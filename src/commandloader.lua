---@class Param
---@field name string
---@field type? string
---@field default? string
---@field required boolean

---@class Vec2
---@field x number
---@field y number

---@class Menu
---@field name string
---@field description? string
---@field render boolean
---@field size Vec2
---@field type MenuType

---@class MenuChoice
---@field name string
---@field text string

---@class ChoiceMenu : Menu
---@field choices MenuChoice[]

---@class Command
---@field name string
---@field text string
---@field description? string
---@field enabled? boolean
---@field params? Param[]
---@field errors? string[]
---@field menus? Menu[]
---@field hasErrors boolean

---@class CommandSource
---@field name string
---@field description? string
---@field enabled? boolean
---@field commands Command[]
---@field filepath string

---@class ValidatorError
---@field error_code number
---@field details ValidatorErrorDetails | string

---@class ValidatorErrorDetails
---@field param_id? number
---@field command_id? string

local weapons = require "game.weapons"
local sandbox = require("lib.sandbox")

local util = require("src.util")
local isEmpty = util.isEmpty

local CommandLoader = {
	---@type CommandSource[]
	sources = {},
	dir = "commands",
}

local path = util.path_join(getWorkingDirectory(), CommandLoader.dir)
if not lfs.attributes(path) then
	lfs.mkdir(path)
end

---@enum MenuType
CommandLoader.menuTypes = {
	CHOICE = "choice",
}

CommandLoader.typeProcessor = {
	["player"] = function(param)
		local playerid = tonumber(param)

		local myid = select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))
		
		if not playerid then
			return false, "Неверный формат ID игрока"
		end

		if playerid == myid then
			return myid
		end

		if not sampIsPlayerConnected(playerid) then
			return false, "Игрок не найден"
		end

		return playerid
	end,
	["number"] = function(param)
		local num = tonumber(param)
		if not num then
			return false, "Неверный формат числа"
		end
		return num
	end,
	["bool"] = function(param)
		local bools = {
			["true"] = true,
			["false"] = false,
			["1"] = true,
			["0"] = false,
		}
		return bools[param] or false, "Неверный формат логического значения, используйте true/false или 1/0"
	end,
	["string"] = function(param)
		return param
	end,
	["vararg"] = function(param)
		return param
	end,
}

CommandLoader.rusTypes = {
	["player"] = u8"игрок",
	["number"] = u8"число",
	["bool"] = u8"логическое значение",
	["string"] = u8"строка",
	["vararg"] = u8"аргумент переменной длины",
}

CommandLoader.env = {
	["wait"] = function(ms)
		state.waitm = tonumber(ms)
	end,
	["time"] = function()
		return os.date("%H:%M:%S")
	end,
	["date"] = function()
		return os.date("%d.%m.%Y")
	end,
	["sexx"] = function()
		return cfg.general.sex == "Мужской" and "" or "а"
	end,
	["my_gun"] = function()
		return getCurrentCharWeapon(PLAYER_PED)
	end,
	["my_gun_weapon"] = function()
		return weapons.names[getCurrentCharWeapon(PLAYER_PED)]
	end,
	["my_lvl"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return sampGetPlayerScore(id)
	end,
	["my_armor"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return sampGetPlayerArmor(id)
	end,
	["my_hp"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return sampGetPlayerHealth(id)
	end,
	["my_id"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return id
	end,
	["my_nick"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		return sampGetPlayerNickname(id)
	end,
	["my_name"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local nick = sampGetPlayerNickname(id)

		return nick:sub(1, nick:find("_") - 1)
	end,
	["my_surname"] = function()
		local _, id = sampGetPlayerIdByCharHandle(PLAYER_PED)
		local nick = sampGetPlayerNickname(id)

		return nick:sub(nick:find("_") + 1)
	end,
	["my_rpnick"] = function()
		return cfg.general.nickname
	end,
	["my_rpname"] = function()
		local nick = cfg.general.nickname

		return nick:sub(1, (nick:find(" ") or nick:find("_")) - 1)
	end,
	["my_rpsurname"] = function()
		local nick = cfg.general.nickname

		return nick:sub((nick:find(" ") or nick:find("_")) + 1)
	end,
	["my_car"] = function()
		if isCharInAnyCar(PLAYER_PED) then 
			local veh = storeCarCharIsInNoSave(PLAYER_PED)
			local idcar = getCarModel(veh)

			return util.arzcars[idcar] or "Неизвестно"
		end
		
		return nil
	end,
	
	["my_carcolor"] = function()
		if isCharInAnyCar(PLAYER_PED) then 
			local veh = storeCarCharIsInNoSave((PLAYER_PED))
			local color1, color2 = getCarColours(veh)
			
			return util.VehicleColoursRussianTable[color1]
		end
		
		return nil
	end,
	["my_fps"] = function()
		return imgui.GetIO().Framerate
	end,
	["random"] = function(n, n2)
		return math.random(n, n2)
	end,
	["city"] = function()
		local city = {
			[0] = "пригород",
			[1] = "Los Santos",
			[2] = "San Fierro",
			[3] = "Las Venturas"
		}

		return city[getCityPlayerIsIn(PLAYER_HANDLE)]
	end,

	["nickid"] = function(id)
		return sampGetPlayerNickname(id)
	end,
	["rpnickid"] = function(id)
		return util.TranslateNick(sampGetPlayerNickname(id))
	end,
	["carid"] = function(id)
		local res, char = sampGetCharHandleBySampPlayerId(id)
		if res and isCharInAnyCar(char) then 
			local veh = storeCarCharIsInNoSave(char)
			local idcar = getCarModel(veh)

			return res and util.arzcars[idcar] or "Неизвестно"
		end
		
		return nil
	end,
	["carcolorid"] = function(id)
		local res, char = sampGetCharHandleBySampPlayerId(id)
		if res and isCharInAnyCar(char) then 
			local veh = storeCarCharIsInNoSave(char)
			local color1, color2 = getCarColours(veh)
			
			return util.VehicleColoursRussianTable[color1]
		end
		
		return nil
	end,
	["inflectcolor"] = function(color)
		if not color then
			return
		end
		return util.inflectColorName(color)
	end,
	["car_id_nearest"] = function(maxDist, maxPlayers)
		maxDist = maxDist or 50
		maxPlayers = maxPlayers or false

		local res, HandleVeh, Distance, posX, posY, posZ, countPlayers = util.GetNearestCarByPed(PLAYER_PED, maxDist, maxPlayers)

		return res and select(2, sampGetVehicleIdByCarHandle(HandleVeh))
	end,
	["car_driver_id"] = function(car_id)
		local res, car = sampGetCarHandleBySampVehicleId(car_id)
		
		if not res then
			return
		end
		local driver = getDriverOfCar(car)

		return driver and select(2, sampGetPlayerIdByCharHandle(driver))
	end,
	["player_id_nearest"] = function(maxDist)
		maxDist = maxDist or 50
		
		local nearest = util.getNearestPedByPed(PLAYER_PED, maxDist)

		return nearest and select(2, sampGetPlayerIdByCharHandle(nearest)) or nil
	end,
}
CommandLoader.env_docs = {
	{
		name="concat_params",
		description="Склеивает параметры в строку, начиная с N и заканчивая N2(по умолчанию до конца параметров)",
		params={"начало?", "конец?"},
		paste = "~{concat_params(1, 3)}~"
	},
	{
		name="wait",
		description="Ждать N миллисекунд",
		params={"мс"},
		paste = "~{wait(1000)}~"
	},
	{
		name="time",
		description="Возвращает текущее время в формате ЧЧ:ММ:СС",
		params={},
	},
	{
		name="date",
		description="Возвращает текущую дату в формате ДД.ММ.ГГГГ",
		params={},
	},
	{
		name="sex",
		description="Возвращает а если пол персонажа женский, иначе пустую строку",
		params={},
	},
	{
		name="my_gun",
		description="Возвращает ID оружия игрока",
		params={},
	},
	{
		name="my_gun_weapon",
		description="Возвращает название оружия игрока",
		params={}
	},
	{
		name="my_lvl",
		description="Возвращает уровень игрока",
		params={}
	},
	{
		name="my_armor",
		description="Возвращает броню игрока",
		params={}
	},
	{
		name="my_hp",
		description="Возвращает здоровье игрока",
		params={}
	},
	{
		name="my_id",
		description="Возвращает ID игрока",
		params={}
	},
	{
		name="my_nick",
		description="Возвращает ник игрока",
		params={}
	},
	{
		name="my_name",
		description="Возвращает имя игрока",
		params={}
	},
	{
		name="my_surname",
		description="Возвращает фамилию игрока",
		params={}
	},
	{
		name="my_rpnick",
		description="Возвращает RP-ник игрока",
		params={}
	},
	{
		name="my_rpname",
		description="Возвращает имя RP-ника игрока",
		params={}
	},
	{
		name="my_rpsurname",
		description="Возвращает фамилию RP-ника игрока",
		params={}
	},
	{
		name="my_car",
		description="Возвращает название машины игрока",
		params={}
	},
	{
		name="my_carcolor",
		description="Возвращает цвет машины игрока",
		params={}
	},
	{
		name="my_fps",
		description="Возвращает FPS",
		params={}
	},
	{
		name="random",
		description="Возвращает случайное число в диапазоне от N до N2",
		params={"N", "N2"},
		paste = "~{random(1, 10)}~"
	},
	{
		name="city",
		description="Возвращает название города, в котором находится игрок",
		params={},
	},
	{
		name="nickid",
		description="Возвращает ник игрока по ID",
		params={"ID"},
		paste = "~{nickid(1)}~"
	},
	{
		name="rpnickid",
		description="Возвращает RP-ник игрока по ID",
		params={"ID"},
		paste = "~{rpnickid(1)}~"
	},
	{
		name="carid",
		description="Возвращает название машины игрока по ID",
		params={"ID"},
		paste = "~{carid(1)}~"
	},
	{
		name="carcolorid",
		description="Возвращает цвет машины игрока по ID",
		params={"ID"},
		paste = "~{carcolorid(1)}~"
	},
	{
		name="inflectcolor",
		description="Склоняет название цвета",
		params={"цвет"},
		paste = "~{inflectcolor(\"красный\")}~"
	},
	{
		name="car_id_nearest",
		description="Возвращает ID ближайшей машины",
		params={"радиус?", "максимальное количество игроков вокруг машины?"},
		paste = "~{car_id_nearest(50)}~"
	},
	{
		name="car_driver_id",
		description="Возвращает ID водителя машины",
		params={"ID машины"},
		paste = "~{car_driver_id(1)}~"
	},
	{
		name="player_id_nearest",
		description="Возвращает ID ближайшего игрока",
		params={"радиус"},
		paste = "~{player_id_nearest(50)}~"
	},
	{
		name="openMenu",
		description="Открывает меню",
		params={"имя меню"},
		paste = "~{openMenu(\"Меню\")}~"
	},
}

function scanDirectory(directory, scanSubdirs)
	local files = {}
	local dirs = {}
	for file in lfs.dir(directory) do
		if file ~= "." and file ~= ".." then
			local filePath = util.path_join(directory, file)
			local mode = lfs.attributes(filePath, "mode")
			if mode == "file" and file:find(".json$") then
				table.insert(files, file)
			elseif scanSubdirs and mode == "directory" then
				local subdirFiles = scanDirectory(filePath, false)
				if next(subdirFiles) then
					dirs[file] = subdirFiles.files
				end
			end
		end
	end

	return files, dirs
end

function CommandLoader.toMimguiTable(source)
	local tbl = {}

	tbl.name = imgui.new.char[128](u8(source.name))
	tbl.description = imgui.new.char[512](u8(source.description))
	tbl.enabled = imgui.new.bool(source.enabled)
	tbl.filepath = imgui.new.char[128](source.filepath)

	tbl.commands = {}
	for _, cmd in ipairs(source.commands) do
		local ctbl = {}
		ctbl.name = imgui.new.char[128](cmd.name)

		ctbl.text = imgui.new.char[15360](u8(cmd.text))

		ctbl.description = imgui.new.char[256](u8(cmd.description))
		ctbl.enabled = imgui.new.bool(cmd.enabled)

		ctbl.params = {}
		for _, param in ipairs(cmd.params) do
			local ptbl = {}
			ptbl.name = imgui.new.char[128](u8(param.name))
			ptbl.type = imgui.new.char[128](param.type)
			ptbl.default = imgui.new.char[128](u8(param.default))
			ptbl.required = imgui.new.bool(param.required)

			table.insert(ctbl.params, ptbl)
		end
		ctbl.menus = {}
		for _, menu in ipairs(cmd.menus or {}) do
			local m = {}
			m.name = imgui.new.char[128](u8(menu.name))
			m.description = imgui.new.char[256](u8(menu.description) or "")
			m.size = {
				x = imgui.new.int(menu.size.x),
				y = imgui.new.int(menu.size.y),
			}
			m.type = imgui.new.char[128](menu.type)
			if menu.type == CommandLoader.menuTypes.CHOICE then
				m.choices = {}
				for _, choice in ipairs(menu.choices) do
					local c = {}
					c.name = imgui.new.char[128](u8(choice.name))
					c.text = imgui.new.char[15360](u8(choice.text))
					table.insert(m.choices, c)
				end
			end
			table.insert(ctbl.menus, m)
		end

		table.insert(tbl.commands, ctbl)
	end

	return tbl
end

function CommandLoader.fromMimguiTable(tbl)
	local source = {}
	source.name = u8:decode(ffi.string(tbl.name))
	source.description = u8:decode(ffi.string(tbl.description))
	source.enabled = tbl.enabled[0]
	source.filepath = ffi.string(tbl.filepath or "")

	source.commands = {}
	for _, cmd in ipairs(tbl.commands) do
		local ctbl = {}
		ctbl.name = ffi.string(cmd.name)
		ctbl.text = u8:decode(ffi.string(cmd.text))
		ctbl.description = u8:decode(ffi.string(cmd.description))
		ctbl.enabled = cmd.enabled[0]

		ctbl.params = {}
		for _, param in ipairs(cmd.params) do
			local ptbl = {}
			ptbl.name = u8:decode(ffi.string(param.name))
			ptbl.type = ffi.string(param.type)
			ptbl.default = u8:decode(ffi.string(param.default))
			ptbl.required = param.required[0]

			table.insert(ctbl.params, ptbl)
		end
		ctbl.menus = {}
		for _, menu in ipairs(cmd.menus or {}) do
			local m = {}
			m.name = u8:decode(ffi.string(menu.name))
			m.description = u8:decode(ffi.string(menu.description) or "")
			m.size = {
				x = menu.size.x[0],
				y = menu.size.y[0],
			}
			m.type = ffi.string(menu.type)
			print(m.type == CommandLoader.menuTypes.CHOICE, m.type, CommandLoader.menuTypes.CHOICE)
			if m.type == CommandLoader.menuTypes.CHOICE then
				m.choices = {}
				for _, choice in ipairs(menu.choices) do
					local c = {}
					c.name = u8:decode(ffi.string(choice.name))
					c.text = u8:decode(ffi.string(choice.text))
					table.insert(m.choices, c)
				end
			end
			table.insert(ctbl.menus, m)
		end

		table.insert(source.commands, ctbl)
	end

	return source
end

---@param source CommandSource
---@param filename string
---@return CommandSource
function CommandLoader.validateSource(source, filename)
	local hasErrors = false
	if isEmpty(source.name) then
		hasErrors = true
		print("Source name is empty in file " .. filename)
	end

	if source.enabled == nil then
		source.enabled = true
	end

	if not source.commands then
		source.commands = {}
	end

	for i, cmd in ipairs(source.commands) do
		local command = CommandLoader.validateCommand(cmd)
		source.commands[i] = command
	end

	return source
end

---@param command table
---@return Command
function CommandLoader.validateCommand(command)
	local hasErrors = false

	if isEmpty(command.name) then
		hasErrors = true
		print(string.format("Command has no name"))
	end

	if isEmpty(command.text) then
		hasErrors = true
		print(string.format("Command %s has no text", command.name))
	end

	if command.enabled == nil then
		command.enabled = true
	end

	if command.params then
		for i, param in ipairs(command.params) do
			if isEmpty(param.name) then
				hasErrors = true
				print(string.format("Param %s has no name in command %s", i, command.name))
			end

			if not param.type then
				param.type = "string"
			end

			if not param.required then
				param.required = true
			end

			if not isEmpty(param.default) and param.required then
				param.required = false
			end

			if not CommandLoader.typeProcessor[param.type] then
				hasErrors = true
				print(string.format("Param %s has no type in command %s", param.name, command.name))
			end
		end
	else
		command.params = {}
	end

	if command.menus then
		for i, menu in ipairs(command.menus) do
			if menu.type == CommandLoader.menuTypes.CHOICE then
				if not menu.choices then
					menu.choices = {}
				end
				for j, choice in ipairs(menu.choices) do
					if isEmpty(choice.name) then
						hasErrors = true
						print(string.format("Choice %s has no name in menu %s in command %s", j, menu.name, command.name))
					end

					if not choice.text then
						choice.text = ""
					end
				end
			else
				hasErrors = true
				print(string.format("Menu %s has unknown type in command %s", menu.name, command.name))
			end
		end
	else
		command.menus = {}
	end

	if hasErrors then
		command.enabled = false
	end

	return command
end

function CommandLoader.processFile(filePath)
	local file = io.open(filePath, "r")
	if not file then
		error("Failed to open file: " .. filePath)
		return
	end

	local content = file:read("*a")
	file:close()
	local success, data = pcall(decodeJson, content)

	if not success then
		print("Failed to parse file " .. filePath)
		return
	end
	if data then
		local source = CommandLoader.validateSource(data, filePath)

		source.filepath = filePath
		table.insert(CommandLoader.sources, source)
	end
end

function CommandLoader.load()
	local files, dirs = scanDirectory(util.path_join(getWorkingDirectory(), CommandLoader.dir), true)
	CommandLoader.processFiles(files, CommandLoader.dir)

	for dir, files in pairs(dirs) do
		local directory = util.path_join(CommandLoader.dir, dir)
		CommandLoader.processFiles(files, directory)
	end
end

function CommandLoader.reload()
	CommandLoader.unregisterCommands()
	CommandLoader.sources = {}
	CommandLoader.load()
	CommandLoader.registerCommands()
end

function CommandLoader.processFiles(files, directory)
	for _, file in ipairs(files) do
		local filePath = util.path_join(getWorkingDirectory(), directory, file)
		CommandLoader.processFile(filePath)
	end
end

function CommandLoader.saveSource(source)
	local file = io.open(source.filepath, "w")
	if not file then
		print("Failed to open file " .. source.filepath)
		return
	end

	source.filepath = nil
	local data = encodeJson(source)
	file:write(data)
	file:close()
end

function CommandLoader.removeSource(source)
	os.remove(source.filepath)
end

function CommandLoader.findSourceByName(name)
	for _, source in ipairs(CommandLoader.sources) do
		if source.name == name then
			return source
		end
	end
end

function CommandLoader.iterateCommands()
	return coroutine.wrap(function()
		for _, source in ipairs(CommandLoader.sources) do
			for _, cmd in ipairs(source.commands) do
				coroutine.yield(cmd)
			end
		end
	end)
end

function CommandLoader.unregisterCommands()
	for cmd in CommandLoader.iterateCommands() do
		sampUnregisterChatCommand(cmd.name)
	end
end

function CommandLoader.registerCommands()
	for _, source in ipairs(CommandLoader.sources) do
		for _, cmd in ipairs(source.commands) do
			if source.enabled and not cmd.hasErrors and cmd.enabled then
				sampRegisterChatCommand(cmd.name, function(params)
					local args = {}
					local aparam = string.gmatch(params, "[^%s]+")
					local vararg = false
					local varargname = nil
					for _, pdata in pairs(cmd.params) do
						local ap = aparam()

						if not ap and pdata.required then
							sampAddChatMessage(
								cmd.name..": Использование: " .. generateUsage(cmd.name, cmd.params),
								-1
							)
							return
						elseif not ap then
							args[pdata.name] = pdata.default or ""
							break
						end

						if pdata.type == "vararg" then
							args[pdata.name] = ap
							vararg = true
							varargname = pdata.name
							break
						end

						local proc = CommandLoader.typeProcessor[pdata.type]

						local arg, err = proc(ap)
						if not arg then
							sampAddChatMessage(cmd.name..": "..err, -1)
							return
						end

						args[pdata.name] = arg
					end
					if vararg then
						for ap in aparam do
							args[varargname] = args[varargname] .. " " .. ap
						end
					end
				

					local env = util.merge(args, cfg.general, CommandLoader.env)

					local function processLine(line, env)
						line = line:gsub("~{(.-)}~", function(expr)
							if not expr:match("^%s*[%w_]+%s*=%s*") and not expr:match("^%s*return%s+") then
								expr = "return "..expr
							end
							local ok, result, penv = pcall(sandbox.run, expr, {
								env = env,
							})
							env = penv
							if not ok then
								print(result)
								sampAddChatMessage(result, -1)
								return ""
							end
							return tostring(result or "")
						end)
						return line
					end
					
					local function processLines(text)
						local i = 1
						for line in text:gmatch("[^\r\n]+") do
							line = processLine(line, env)
							if state.waitm then
								wait(state.waitm)
								state.waitm = nil
							elseif i > 1 and not isEmpty(line) then
								wait(cfg.general.default_delay)
							end
							if not isEmpty(line) then
								i = i + 1
								sampProcessChatInput(line)
							end
						end
					end

					function env.openMenu(name)
						---@type Menu
						local menu = util.findByField(cmd.menus, "name", name)
						if not menu then
							error("Menu not found: " .. name)
						end
						
						if menu.type == CommandLoader.menuTypes.CHOICE then
							table.insert(state.menus, util.merge(menu, {
								render = imgui.new.bool(true),
								onChoice = function (choice)
									env.choice = choice.name
									lua_thread.create(function()
										processLines(choice.text)
									end)
								end
							}))
						end
					end

					function env.concatParams(start, finish)
						local start = start or 1
						local finish = finish or #args

						local result = ""
						for i = start, finish do
							result = result .. args[i] .. " "
						end

						return result
					end

					lua_thread.create(function()
						processLines(cmd.text)
					end)
				end)
			end
		end
	end

	sampRegisterChatCommand("eval", function(params)
		local ok, result = xpcall(sandbox.run, debug.traceback, "return "..params, {
			env = util.merge(cfg.general, CommandLoader.env),
		})

		if not ok then
			print(result)
		end

		sampAddChatMessage(tostring(result), -1)
	end)
end

function CommandLoader.sourceCount()
	return #CommandLoader.sources
end

function CommandLoader.commandCount()
	local count = 0
	for _ in CommandLoader.iterateCommands() do
		count = count + 1
	end
	return count
end

return CommandLoader
