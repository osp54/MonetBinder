script_name("MonetBinder")
script_author("OSPx")
script_description([[
	A functional binder in Lua for Arizona RP Mobile utilizing the MonetLoader Runtime
	Функциональный биндер на Lua для Arizona RP Mobile
]])
script_url("https://github.com/osp54/MonetBinder")
script_version("1.0.1")

PATH_SEPARATOR = "/"
if MONET_VERSION == nil then
	PATH_SEPARATOR = "\\"
end

ffi = require("ffi")
lfs = require("lfs")
imgui = require("mimgui")

jsoncfg = require("lib.jsoncfg")
android = require("lib.android")

util = require("src.util")
imutil = require("src.imgui_util")
doubleclickped = require("src.doubleclickped")
commandloader = require("src.commandloader")

fa = require("fAwesome6_solid")
encoding = require("encoding")
encoding.default = "CP1251"
u8 = encoding.UTF8

cfg = {
	general = {
		default_delay = 1000,
		nickname = "",
		fraction = "",
		rank = "",
		rank_number = 0,
	},
	ui = {
		monet_binder_button = true,
		monet_binder_button_pos = {
			x = 340,
			y = 225,
		},
		monet_binder_button_size = {
			x = 60,
			y = 60,
		},
	},
}

local function mimguiState()
	local state = {}
	state.renderMainMenu = imgui.new.bool(false)
	state.mainMenuMenuPos = imgui.ImVec2(0, 0)
	state.renderFastMenu = imgui.new.bool(false)

	state.fastMenuPlayerId = nil
	state.fastMenuPos = imgui.ImVec2(0, 0)

	state.defaultDelayInput = imgui.new.int(cfg.general.default_delay)
	state.nicknameInput = imgui.new.char[256](u8(cfg.general.nickname))
	state.fractionInput = imgui.new.char[256](u8(cfg.general.fraction))
	state.rankInput = imgui.new.char[256](u8(cfg.general.rank))
	state.ranks = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "10" }
	state.ImRanks = imgui.new["const char*"][#state.ranks](state.ranks)
	state.rankNumberInput = imgui.new.int(cfg.general.rank_number - 1)

	state.monetBinderButton = imgui.new.bool(cfg.ui.monet_binder_button)
	state.monetBinderButtonMove = false

	state.selectedProfile = 0
	state.currentMsource = nil
	state.currentCommand = nil

	state.menus = {}
	return state
end

local allowedLuaDoc = {
	{
		is_function = true,
		name = "assert",
		description = "Вызывает ошибку, если условие ложно",
		params = { "condition", "message" },
	},
	{
		is_function = true,
		name = "error",
		description = "Вызывает ошибку",
		params = { "message" },
	},
	{
		is_function = true,
		name = "ipairs",
		description = "Возвращает итератор для перебора массива в порядке возрастания индекса",
		params = { "t" },
	},
	{
		is_function = true,
		name = "next",
		description = "Возвращает следующий элемент таблицы",
		params = { "table", "index" },
	},
	{
		is_function = true,
		name = "pairs",
		description = "Возвращает итератор для перебора таблицы в случайном порядке",
		params = { "t" },
	},
	{
		is_function = true,
		name = "pcall",
		description = "Вызывает функцию в защищенном режиме",
		params = { "function", "..." },
	},
	{
		is_function = true,
		name = "select",
		description = "Возвращает все параметры функции, начиная с индекса",
		params = { "index", "..." },
	},
	{
		is_function = true,
		name = "tonumber",
		description = "Преобразует строку в число",
		params = { "e", "base" },
	},
	{
		is_function = true,
		name = "tostring",
		description = "Преобразует значение в строку",
		params = { "e" },
	},
	{
		is_function = true,
		name = "type",
		description = "Возвращает тип значения",
		params = { "v" },
	},
	{
		is_function = true,
		name = "unpack",
		description = "Разпаковывает массив в список значений",
		params = { "list", "i", "j" },
	},
	{
		is_function = true,
		name = "xpcall",
		description = "Вызывает функцию в защищенном режиме",
		params = { "function", "msgh", "..." },
	},
	{
		is_module = true,
		name = "coroutine",
		description = "Модуль для работы с корутинами",
		doc = {
			{
				is_function = true,
				name = "create",
				description = "Создает новую корутину",
				params = { "f" },
			},
			{
				is_function = true,
				name = "resume",
				description = "Запускает корутину",
				params = { "co", "..." },
			},
			{
				is_function = true,
				name = "running",
				description = "Возвращает текущую корутину",
			},
			{
				is_function = true,
				name = "status",
				description = "Возвращает статус корутины",
				params = { "co" },
			},
			{
				is_function = true,
				name = "wrap",
				description = "Создает защищенную функцию",
				params = { "f" },
			},
			{
				is_function = true,
				name = "yield",
				description = "Приостанавливает корутину",
				params = { "..." },
			},
		},
	},
	{
		is_module = true,
		name = "math",
		description = "Модуль для математических операций",
		doc = {
			{
				is_function = true,
				name = "abs",
				description = "Модуль числа",
				params = { "x" },
			},
			{
				is_function = true,
				name = "acos",
				description = "Арккосинус",
				params = { "x" },
			},
			{
				is_function = true,
				name = "asin",
				description = "Арксинус",
				params = { "x" },
			},
			{
				is_function = true,
				name = "atan",
				description = "Арктангенс",
				params = { "x" },
			},
			{
				is_function = true,
				name = "atan2",
				description = "Арктангенс двух аргументов",
				params = { "y", "x" },
			},
			{
				is_function = true,
				name = "ceil",
				description = "Округление вверх",
				params = { "x" },
			},
			{
				is_function = true,
				name = "cos",
				description = "Косинус",
				params = { "x" },
			},
			{
				is_function = true,
				name = "cosh",
				description = "Гиперболический косинус",
				params = { "x" },
			},
			{
				is_function = true,
				name = "deg",
				description = "Преобразует радианы в градусы",
				params = { "x" },
			},
			{
				is_function = true,
				name = "exp",
				description = "Экспонента",
				params = { "x" },
			},
			{
				is_function = true,
				name = "fmod",
				description = "Остаток от деления",
				params = { "x", "y" },
			},
			{
				is_function = true,
				name = "floor",
				description = "Округление вниз",
				params = { "x" },
			},
			{
				is_function = true,
				name = "frexp",
				description = "Разбиение числа на мантиссу и экспоненту",
				params = { "x" },
			},
			{
				is_const = true,
				name = "huge",
				description = "Бесконечность",
			},
			{
				is_function = true,
				name = "ldexp",
				description = "Умножение числа на 2 в степени",
				params = { "m", "e" },
			},
			{
				is_function = true,
				name = "log",
				description = "Натуральный логарифм",
				params = { "x", "base" },
			},
			{
				is_function = true,
				name = "log10",
				description = "Десятичный логарифм",
				params = { "x" },
			},
			{
				is_function = true,
				name = "max",
				description = "Максимальное число",
				params = { "x", "..." },
			},
			{
				is_function = true,
				name = "min",
				description = "Минимальное число",
				params = { "x", "..." },
			},
			{
				is_function = true,
				name = "modf",
				description = "Целая и дробная часть числа",
				params = { "x" },
			},
			{
				is_const = true,
				name = "pi",
				description = "Число пи",
			},
			{
				is_function = true,
				name = "pow",
				description = "Возведение в степень",
				params = { "x", "y" },
			},
			{
				is_function = true,
				name = "rad",
				description = "Преобразует градусы в радианы",
				params = { "x" },
			},
			{
				is_function = true,
				name = "random",
				description = "Случайное число",
				params = { "m", "n" },
			},
			{
				is_function = true,
				name = "sin",
				description = "Синус",
				params = { "x" },
			},
			{
				is_function = true,
				name = "sinh",
				description = "Гиперболический синус",
				params = { "x" },
			},
			{
				is_function = true,
				name = "sqrt",
				description = "Квадратный корень",
				params = { "x" },
			},
			{
				is_function = true,
				name = "tan",
				description = "Тангенс",
				params = { "x" },
			},
			{
				is_function = true,
				name = "tanh",
				description = "Гиперболический тангенс",
				params = { "x" },
			},
		},
	},
	{
		is_module = true,
		name = "os",
		description = "Модуль для работы с операционной системой",
		doc = {
			{
				is_function = true,
				name = "clock",
				description = "Время работы программы",
			},
			{
				is_function = true,
				name = "difftime",
				description = "Разница между временем",
				params = { "t2", "t1" },
			},
			{
				is_function = true,
				name = "time",
				description = "Текущее время",
			},
		},
	},
	{
		is_module = true,
		name = "string",
		description = "Модуль для работы со строками",
		doc = {
			{
				is_function = true,
				name = "byte",
				description = "Возвращает числовое значение символа",
				params = { "s", "i", "j" },
			},
			{
				is_function = true,
				name = "char",
				description = "Возвращает символ по коду",
				params = { "..." },
			},
			{
				is_function = true,
				name = "find",
				description = "Поиск подстроки",
				params = { "s", "pattern", "init", "plain" },
			},
			{
				is_function = true,
				name = "format",
				description = "Форматирование строки",
				params = { "formatstring", "..." },
			},
			{
				is_function = true,
				name = "gmatch",
				description = "Итератор для поиска подстроки",
				params = { "s", "pattern" },
			},
			{
				is_function = true,
				name = "gsub",
				description = "Замена подстроки",
				params = { "s", "pattern", "repl", "n" },
			},
			{
				is_function = true,
				name = "len",
				description = "Длина строки",
				params = { "s" },
			},
			{
				is_function = true,
				name = "lower",
				description = "Преобразует строку в нижний регистр",
				params = { "s" },
			},
			{
				is_function = true,
				name = "match",
				description = "Поиск подстроки",
				params = { "s", "pattern", "init" },
			},
			{
				is_function = true,
				name = "reverse",
				description = "Переворачивает строку",
				params = { "s" },
			},
			{
				is_function = true,
				name = "sub",
				description = "Возвращает подстроку",
				params = { "s", "i", "j" },
			},
			{
				is_function = true,
				name = "upper",
				description = "Преобразует строку в верхний регистр",
				params = { "s" },
			},
		},
	},
	{
		is_module = true,
		name = "table",
		description = "Модуль для работы с таблицами",
		doc = {
			{
				is_function = true,
				name = "insert",
				description = "Добавляет элемент в таблицу",
				params = { "t", "pos", "value" },
			},
			{
				is_function = true,
				name = "maxn",
				description = "Возвращает максимальный индекс массива",
				params = { "t" },
			},
			{
				is_function = true,
				name = "remove",
				description = "Удаляет элемент из таблицы",
				params = { "t", "pos" },
			},
			{
				is_function = true,
				name = "sort",
				description = "Сортирует таблицу",
				params = { "t", "comp" },
			},
		},
	},
}

MDS = MONET_DPI_SCALE or 1
SOURCES_META_URL = "https://raw.githubusercontent.com/osp54/MonetBinder/main/sourcesmeta.json"
cfg = jsoncfg.load(cfg, "MonetBinder", ".json") or cfg
state = mimguiState()

doubleclickped.onDoubleClickedPed = function(ped, x, y)
	local res, id = sampGetPlayerIdByCharHandle(ped)

	if res then
		state.fastMenuPlayerId = id
		state.fastMenuPos = imgui.ImVec2(x, y)
		state.renderFastMenu[0] = true
	end
end

local function isGeneralSettingsChanged()
	return state.defaultDelayInput[0] ~= cfg.general.default_delay
		or ffi.string(state.nicknameInput) ~= cfg.general.nickname
		or ffi.string(state.fractionInput) ~= cfg.general.fraction
		or ffi.string(state.rankInput) ~= cfg.general.rank
		or state.rankNumberInput[0] + 1 ~= cfg.general.rank_number
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	fa.Init(14 * MDS)

	imgui.GetStyle():ScaleAllSizes(MDS)
	darkTheme()
end)

imgui.OnFrame(function()
	return state.renderMainMenu[0]
end, function(player)
	local screenX, screenY = getScreenResolution()

	imgui.SetNextWindowSize(imgui.ImVec2(700 * MDS, 400 * MDS), imgui.Cond.FirstUseEver)
	imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.Begin(u8("MonetBinder"), state.renderMainMenu)
	state.mainMenuMenuPos = imgui.GetWindowPos()

	imgui.BeginTabBar("##tabbar")
	if imgui.BeginTabItem(u8("Общие настройки")) then
		imutil.Setting(
			u8("Задержка"),
			u8("Задержка (мс): %d"):format(state.defaultDelayInput[0]),
			function()
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputInt("##defaultdelay", state.defaultDelayInput, 0)
			end
		)
		imgui.Separator()
		imutil.Setting(
			u8("Ваше РП имя"),
			u8("Ваше РП имя: %s"):format(ffi.string(state.nicknameInput)),
			function()
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputText("##nickname", state.nicknameInput, 256)
			end
		)
		imgui.Separator()
		imutil.Setting(
			u8("Ваша фракция"),
			u8("Ваша фракция: %s"):format(ffi.string(state.fractionInput)),
			function()
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputText("##fraction", state.fractionInput, 256)
			end
		)
		imgui.Separator()
		imutil.Setting(
			u8("Ваш ранг"),
			u8("Ваш ранг: %s (%d)"):format(ffi.string(state.rankInput), state.rankNumberInput[0] + 1),
			function()
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputText("##rank", state.rankInput, 256)
				imutil.CenterText(u8("Номер ранга:"))
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.Combo("##ranknumber", state.rankNumberInput, state.ImRanks, #state.ranks)
			end
		)
		local buttonlbl = u8(" Кнопка MonetBinder")
		if
			imutil.ToggleButtonIcon(
				fa.TOGGLE_ON .. buttonlbl,
				fa.TOGGLE_OFF .. buttonlbl,
				cfg.ui.monet_binder_button,
				imgui.ImVec2(imutil.GetMiddleButtonX(2), 30)
			)
		then
			cfg.ui.monet_binder_button = not cfg.ui.monet_binder_button
			state.monetBinderButton[0] = cfg.ui.monet_binder_button
		end
		imgui.SameLine()
		local buttonmovelbl = u8(" Перемещение кнопки")
		if
			imutil.ToggleButtonIcon(
				fa.TOGGLE_ON .. buttonmovelbl,
				fa.TOGGLE_OFF .. buttonmovelbl,
				state.monetBinderButtonMove,
				imgui.ImVec2(imutil.GetMiddleButtonX(2), 30)
			)
		then
			state.monetBinderButtonMove = not state.monetBinderButtonMove
		end

		if isGeneralSettingsChanged() then
			cfg.general.default_delay = state.defaultDelayInput[0]
			cfg.general.nickname = u8:decode(ffi.string(state.nicknameInput))
			cfg.general.rank = u8:decode(ffi.string(state.rankInput))
			cfg.general.rank_number = state.rankNumberInput[0] + 1
			jsoncfg.save(cfg, "MonetBinder", ".json")
		end
		if
			imgui.Button(
				fa.WAND_SPARKLES .. u8(" Заполнить автоматически"),
				imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)
			)
		then
			check_stats = true
			sampSendChat("/stats")
		end
		imgui.EndTabItem()
	end

	if imgui.BeginTabItem(u8("Профили, команды")) then
		imgui.BeginChild(
			"##profiles-vertical-choose",
			imgui.ImVec2((imgui.GetWindowWidth() * 0.35) - imgui.GetStyle().FramePadding.x * 2, 0),
			true
		)
		if imgui.Button(fa.CIRCLE_PLUS, imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
			table.insert(commandloader.sources, {
				name = "profile" .. #commandloader.sources + 1,
				description = "",
				commands = {},
				enabled = true,
				filepath = getWorkingDirectory()
					.. PATH_SEPARATOR
					.. commandloader.dir
					.. PATH_SEPARATOR
					.. "profile"
					.. tostring(#commandloader.sources + 1)
					.. ".json",
			})
			state.selectedProfile = #commandloader.sources
			state.currentMsource = commandloader.toMimguiTable(commandloader.sources[state.selectedProfile])
		end
		imgui.SameLine()
		if imgui.Button(fa.GLOBE, imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
			imgui.OpenPopup(u8("Профили, созданные другими игроками"))
		end
		if
			imgui.BeginPopupModal(
				u8("Профили, созданные другими игроками"),
				_,
				imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
			)
		then
			imgui.SetWindowSizeVec2(imgui.ImVec2(700 * MDS, 400 * MDS))

			if
				imgui.Button(
					fa.ARROWS_ROTATE .. u8(" Перезагрузить список"),
					imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)
				)
			then
				state.sources_meta = nil
				state.sources_meta_loading = false
			end

			if state.sources_meta and state.sources_meta.error then
				imgui.SetCursorPosY(imgui.GetWindowHeight() / 2)
				imutil.CenterError(u8("Ошибка загрузки: %s"):format(state.sources_meta.error))
			end

			if state.sources_meta and not state.sources_meta.error then
				imgui.Columns(4, "##sources", true)
				imgui.Text(u8("Имя"))
				imgui.NextColumn()
				imgui.Text(u8("Описание"))
				imgui.NextColumn()
				imgui.Text(u8("Автор"))
				imgui.NextColumn()
				imgui.Text(u8("Действие"))
				imgui.NextColumn()
				imgui.Separator()
				for i, source in ipairs(state.sources_meta) do
					if not source.exsource then
						source.exsource = commandloader.findSourceByName(u8:decode(source.name)) or {}
					end
					if source.error then
						imgui.Columns(1)
						imutil.CenterError(u8("Ошибка загрузки: %s"):format(source.error))
						imgui.Columns(4, "##sources", true)
					elseif source.download_progress_percent then
						imgui.Columns(1)
						imgui.ProgressBar(source.download_progress_percent / 100, imgui.ImVec2(-1, 15 * MDS))
						imgui.Columns(4, "##sources", true)

						if source.downloaded_at + 5 < os.time() then
							source.downloaded_at = nil
							source.download_progress_percent = nil
							source.downloaded = nil
						end
					end
					imgui.Text(source.name)
					imgui.NextColumn()
					imgui.Text(source.description)
					imgui.NextColumn()
					imgui.Text(source.author)
					imgui.NextColumn()
					if
						imgui.Button(
							source.exsource.name and fa.ARROWS_ROTATE or fa.DOWNLOAD,
							imgui.ImVec2(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x, 30 * MDS)
						)
					then
						local filename = source.download_link:match("([^/]+)$")
						local filepath = source.exsource.name and source.exsource.filepath
							or getWorkingDirectory()
								.. PATH_SEPARATOR
								.. commandloader.dir
								.. PATH_SEPARATOR
								.. filename

						util.downloadToFile(source.download_link, filepath, function(type, pos, total_size)
							if type == "downloading" then
								state.sources_meta[i].download_progress_percent = (pos / total_size) * 100
							elseif type == "error" then
								state.sources_meta[i].error = pos
							elseif type == "finished" then
								state.sources_meta[i].download_progress_percent = 100
								state.sources_meta[i].downloaded = true
								state.sources_meta[i].downloaded_at = os.time()

								commandloader.reload()
							end
						end)
					end
					imgui.NextColumn()
					imgui.Separator()
				end
				imgui.Columns(1)
			end

			if state.sources_meta_loading then
				imgui.SetCursorPosY(imgui.GetWindowHeight() / 2)
				imutil.CenterText(fa.SPINNER .. u8(" Загрузка..."))
			end

			if not state.sources_meta and not state.sources_meta_loading then
				state.sources_meta_loading = true

				local t = util.newThread(function(url)
					local requests = require("requests")

					local ok, res = pcall(requests.get, url)

					if not ok then
						return false, res
					end

					if res.status_code == 200 then
						return true, res.text
					else
						return false, res.status_code
					end
				end)

				t:run(SOURCES_META_URL)
				t:listen(function(res)
					state.sources_meta_loading = false

					local ok, data = pcall(decodeJson, res)
					if not ok then
						state.sources_meta = { error = data }
					else
						state.sources_meta = data
					end
				end, function(err)
					state.sources_meta = { error = err }
				end)
			end

			imgui.Dummy(imgui.ImVec2(0, 30 * MDS))
			imgui.SetCursorPosY(imgui.GetWindowHeight() - imgui.GetStyle().FramePadding.y - 30 * MDS)
			if imgui.Button(fa.XMARK .. u8(" Закрыть"), imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)) then
				imgui.CloseCurrentPopup()
			end
			imgui.EndPopup()
		end
		for i, source in pairs(commandloader.sources) do
			if
				imgui.Button(
					u8(source.name),
					imgui.ImVec2(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2, 30 * MDS)
				)
			then
				state.selectedProfile = i
				state.currentMsource = commandloader.toMimguiTable(source)
			end
		end
		imgui.EndChild()
		imgui.SameLine()
		imgui.BeginChild("##profile", imgui.ImVec2(0, 0), true)
		if state.selectedProfile == 0 then
			imgui.SetCursorPosY(imgui.GetWindowHeight() / 2)
			imutil.CenterText(u8("Выберите профиль"))

			imgui.EndChild()
			imgui.EndTabItem()
		end

		local source = commandloader.sources[state.selectedProfile]
		if source and state.currentMsource then
			if imgui.Button(fa.TRASH, imgui.ImVec2(imutil.GetMiddleButtonX(3), 30 * MDS)) then
				commandloader.removeSource(source)
				commandloader.sources[state.selectedProfile] = nil

				if #commandloader.sources > 0 then
					state.selectedProfile = 1
					state.currentMsource = commandloader.toMimguiTable(commandloader.sources[state.selectedProfile])
				else
					state.currentMsource = nil
					state.selectedProfile = 0
				end
			end
			if not state.currentMsource then
				imgui.EndChild()
				imgui.EndTabItem()
				return
			end

			imgui.SameLine()
			if imgui.Button(fa.FLOPPY_DISK, imgui.ImVec2(imutil.GetMiddleButtonX(3), 30 * MDS)) then
				commandloader.sources[state.selectedProfile] = commandloader.fromMimguiTable(state.currentMsource)
				commandloader.saveSource(commandloader.sources[state.selectedProfile])
				commandloader.reload()
			end
			imgui.SameLine()
			if
				imutil.ToggleButtonIcon(
					fa.TOGGLE_ON,
					fa.TOGGLE_OFF,
					state.currentMsource.enabled[0],
					imgui.ImVec2(imutil.GetMiddleButtonX(3), 30 * MDS)
				)
			then
				state.currentMsource.enabled[0] = not state.currentMsource.enabled[0]
			end
			imgui.Separator()
			imutil.Setting(u8("Имя"), u8("Имя: %s"):format(ffi.string(state.currentMsource.name)), function()
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputText("##name", state.currentMsource.name, 256)
			end)
			imgui.Separator()
			imutil.Setting(
				u8("Описание"),
				imutil.shortifyText(u8("Описание: %s"):format(ffi.string(state.currentMsource.description))),
				function()
					imgui.SetWindowSizeVec2(imgui.ImVec2(450 * MDS, 400 * MDS))
					imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
					imgui.InputTextMultiline(
						"##description",
						state.currentMsource.description,
						256,
						imgui.ImVec2(0, imgui.GetWindowHeight() - 100 * MDS) -- ch
					)
				end
			)
			imgui.BeginChild("##commands", imgui.ImVec2(0, 0), true)
			if
				imgui.Button(
					fa.CIRCLE_PLUS .. u8(" Создать команду"),
					imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)
				)
			then
				table.insert(state.currentMsource.commands, {
					name = imgui.new.char[256]("cmd" .. #state.currentMsource.commands + 1),
					description = imgui.new.char[256](),
					text = imgui.new.char[1024](),
					enabled = imgui.new.bool(true),
					params = {},
				})
			end
			imgui.Columns(3, "##commands", true)
			imgui.Text(u8("Команда"))
			imgui.NextColumn()
			imgui.Text(u8("Описание"))
			imgui.NextColumn()
			imgui.Text(u8("Действие"))
			imgui.NextColumn()
			imgui.Separator()
			for i, command in pairs(state.currentMsource.commands) do
				local cmdname = ffi.string(command.name)
				imgui.Text("/" .. cmdname)
				imgui.NextColumn()
				imgui.Text(imutil.shortifyText(ffi.string(command.description), imgui.GetColumnWidth()))
				imgui.NextColumn()
				if
					imutil.ToggleButtonIcon(
						fa.TOGGLE_ON .. "##" .. cmdname,
						fa.TOGGLE_OFF .. "##" .. cmdname,
						command.enabled[0],
						imgui.ImVec2(imutil.GetMiddleColumnX(3), 30 * MDS)
					)
				then
					command.enabled[0] = not command.enabled[0]
				end
				imgui.SameLine()
				if imgui.Button(fa.TRASH .. "##" .. cmdname, imgui.ImVec2(imutil.GetMiddleColumnX(3), 30 * MDS)) then
					table.remove(state.currentMsource.commands, i)
				end
				imgui.SameLine()
				if imgui.Button(fa.PEN .. "##" .. cmdname, imgui.ImVec2(imutil.GetMiddleColumnX(3), 30 * MDS)) then
					state.currentCommand = i
					imgui.OpenPopup(u8("Редактирование команды"))
				end
				imgui.NextColumn()
				imgui.Separator()
			end
			if
				imgui.BeginPopupModal(
					u8("Редактирование команды"),
					_,
					imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
				)
			then
				local command = state.currentMsource.commands[state.currentCommand]

				imgui.SetWindowSizeVec2(imgui.ImVec2(700 * MDS, 400 * MDS))
				if util.isEmpty(ffi.string(command.name)) then
					imutil.CenterError(u8(commandloader.errorDescriptions[2]))
				end
				imutil.Setting(
					u8("Название"),
					u8("Название: %s"):format(ffi.string(command.name)),
					function()
						imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
						imgui.InputText("##commandname", command.name, 256)
					end
				)
				imgui.Separator()
				imutil.Setting(
					u8("Описание"),
					u8("Описание: %s"):format(ffi.string(command.description)),
					function()
						imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
						imgui.InputText("##commanddescription", command.description, 256)
					end
				)
				imgui.Separator()

				if util.isEmpty(ffi.string(command.text)) then
					imutil.CenterError(u8(commandloader.errorDescriptions[3]))
				end
				imutil.Setting(
					u8("Текст"),
					imutil.shortifyText(u8("Текст: %s"):format(ffi.string(command.text):gsub("\n", ""))),
					function()
						imgui.SetWindowSizeVec2(imgui.ImVec2(600 * MDS, 300 * MDS))

						imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
						imgui.InputTextMultiline(
							"##commandtext",
							command.text,
							1024,
							imgui.ImVec2(0, imgui.GetWindowHeight() - 70 - imgui.GetStyle().FramePadding.y * 2)
						)

						imgui.SetCursorPosY(imgui.GetWindowHeight() - 30 * MDS - imgui.GetStyle().FramePadding.y * 2)
						if
							imgui.Button(
								fa.TAGS .. u8(" Переменные/Функции"),
								imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)
							)
						then
							imgui.OpenPopup(u8("Переменные/Функции"))
						end

						if
							imgui.BeginPopupModal(
								u8("Переменные/Функции"),
								_,
								imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
							)
						then
							imgui.SetWindowSizeVec2(imgui.ImVec2(700 * MDS, 400 * MDS))
							imutil.CenterText(
								u8(
									"Переменные, которые можно использовать в тексте команды:"
								)
							)
							imgui.Separator()
							for k, v in pairs(cfg.general) do
								imgui.Text(u8("~{%s}~ -- %s"):format(k, u8(v)))
								imgui.Separator()
							end

							imutil.CenterText(
								u8(
									"Функции, которые можно использовать в тексте команды:"
								)
							)
							imgui.Separator()
							for i, doc in ipairs(commandloader.env_docs) do
								local params = #doc.params > 0 and "(" .. table.concat(doc.params, ", ") .. ")" or "()"
								imgui.Text(u8("~{%s%s}~ %s"):format(doc.name, u8(params), u8(doc.description)))
								imgui.Separator()
							end

							if imgui.CollapsingHeader(u8("Доступные функции Lua")) then
								if
									imgui.Button(
										fa.LINK .. u8(" Открыть документацию Lua"),
										imgui.ImVec2(imutil.GetMiddleButtonX(1), 20 * MDS)
									)
								then
									util.openLink("https://www.lua.org/manual/5.1/")
								end
								function processAllowedLuaDoc(data, prefix)
									for i, v in ipairs(data) do
										local fullKey = prefix and (prefix .. "." .. v.name) or v.name
										if v.is_const then
											imgui.Text(u8("~{%s}~ -- %s"):format(fullKey, u8(v.description)))
											imgui.Separator()
										end

										if v.is_function then
											local params = "(" .. table.concat(v.params or {}, ", ") .. ")"
											imgui.Text(u8("~{%s%s}~ %s"):format(fullKey, params, u8(v.description)))
											imgui.Separator()
										end

										if v.is_module then
											imutil.CenterText(u8("Модуль: %s"):format(fullKey))
											imutil.CenterText(u8(v.description))
											processAllowedLuaDoc(v.doc, fullKey)
										end
									end
								end
								processAllowedLuaDoc(allowedLuaDoc)
							end

							imgui.Dummy(imgui.ImVec2(0, 30 * MDS))
							--imgui.SetCursorPosY(imgui.GetWindowHeight() - imgui.GetFrameHeightWithSpacing())
							imgui.SetCursorPosY(
								imgui.GetWindowHeight()
									- imgui.GetStyle().FramePadding.y
									- 30 * MDS
									+ imgui.GetScrollY()
							)
							if
								imgui.Button(
									fa.XMARK .. u8(" Закрыть"),
									imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)
								)
							then
								imgui.CloseCurrentPopup()
							end
							imgui.EndPopup()
						end
						imgui.SameLine()
						if
							imgui.Button(
								fa.XMARK .. u8(" Закрыть"),
								imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)
							)
						then
							imgui.CloseCurrentPopup()
						end
					end,
					false
				)

				imutil.CenterText(u8("Параметры"))
				imgui.Separator()
				imgui.Columns(4, "##params", true)
				imgui.Text(u8("Параметр"))
				imgui.NextColumn()
				imgui.Text(u8("Тип"))
				imgui.NextColumn()
				imgui.Text(u8("По умолчанию"))
				imgui.NextColumn()
				imgui.Text(u8("Действие"))
				imgui.NextColumn()
				imgui.Separator()

				for i, param in pairs(command.params) do
					if not param.ImTypes then
						param.types = {}
						param.selectedType = imgui.new.int(0)
						local i = 0
						for k, v in pairs(commandloader.typeProcessor) do
							table.insert(param.types, k)
							if ffi.string(param.type) == k then
								param.selectedType = imgui.new.int(i)
							end
							i = i + 1
						end
						param.ImTypes = imgui.new["const char*"][#param.types](param.types)
					end
					imgui.SetNextItemWidth(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2)
					imgui.InputText("##paramname" .. i, param.name, 256)
					imgui.NextColumn()

					imgui.SetNextItemWidth(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2)
					imgui.Combo("##paramtype" .. i, param.selectedType, param.ImTypes, #param.types)
					imgui.NextColumn()

					imgui.SetNextItemWidth(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2)
					imgui.InputText("##paramdefault" .. i, param.default, 256)
					imgui.NextColumn()
					if
						imgui.Button(
							fa.TRASH .. "##param" .. i,
							imgui.ImVec2(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2, 30 * MDS)
						)
					then
						table.remove(command.params, i)
					end
					imgui.NextColumn()
					imgui.Separator()
				end
				imgui.Columns(1)
				if
					imgui.Button(
						fa.CIRCLE_PLUS .. u8(" Добавить параметр"),
						imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)
					)
				then
					table.insert(command.params, {
						name = imgui.new.char[256]("param" .. #command.params + 1),
						type = "string",
						default = imgui.new.char[256](),
					})
				end

				imgui.Dummy(imgui.ImVec2(0, 30 * MDS))
				imgui.SetCursorPosY(imgui.GetWindowHeight() - imgui.GetStyle().FramePadding.y - 30 + imgui.GetScrollY())
				if imgui.Button(fa.FLOPPY_DISK, imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)) then
					if not util.isEmpty(ffi.string(command.name)) and not util.isEmpty(ffi.string(command.text)) then
						for _, param in pairs(command.params) do
							param.type = param.types[param.selectedType[0] + 1]
							param.required = imgui.new.bool(util.isEmpty(ffi.string(param.default)))
						end

						commandloader.sources[state.selectedProfile] =
							commandloader.fromMimguiTable(state.currentMsource)
						commandloader.saveSource(commandloader.sources[state.selectedProfile])
						commandloader.reload()
						android:showToast(u8("Команда сохранена"), 1)
						imgui.CloseCurrentPopup()
					else
						android:showToast(u8("Заполните все поля"), 1)
					end
				end
				imgui.EndPopup()
			end
			imgui.EndChild()
		end
		imgui.EndChild()
		imgui.EndTabItem()
	end

	imgui.End()
end)

imgui.OnFrame(function()
	return state.monetBinderButton[0]
end, function(player)
	local pos = imgui.ImVec2(cfg.ui.monet_binder_button_pos.x, cfg.ui.monet_binder_button_pos.y)
	local size = imgui.ImVec2(cfg.ui.monet_binder_button_size.x, cfg.ui.monet_binder_button_size.y)
	res, pos, size =
		imutil.BackgroundButton(fa.TERMINAL, state.monetBinderButton, pos, size, nil, state.monetBinderButtonMove)

	if res then
		state.renderMainMenu[0] = not state.renderMainMenu[0]
	end

	cfg.ui.monet_binder_button_pos.x = pos.x
	cfg.ui.monet_binder_button_pos.y = pos.y

	cfg.ui.monet_binder_button_size.x = size.x
	cfg.ui.monet_binder_button_size.y = size.y
end)

imgui.OnFrame(function()
	return true
end, function(player)
	for i, menu in ipairs(state.menus) do
		if menu.render[0] then
			imgui.SetNextWindowSize(imgui.ImVec2(200 * MDS, 125 * MDS), imgui.Cond.FirstUseEver)
			local screenX, screenY = getScreenResolution()

			imgui.SetNextWindowPos(
				imgui.ImVec2(screenX / 2, screenY - 100),
				imgui.Cond.FirstUseEver,
				imgui.ImVec2(0.5, 0.5)
			)
			imgui.Begin(u8(menu.name .. "##" .. i), menu.render)
			imgui.Separator()
			for i, choice in ipairs(menu.choices) do
				local middleX = imutil.GetMiddleButtonX(2)

				if imgui.Button(u8(choice.name), imgui.ImVec2(middleX, 30 * MDS)) then
					lua_thread.create(function()
						local i = 1
						for line in string.gmatch(choice.text, "[^\r\n]+") do
							if state.waitm then
								wait(state.waitm)
							elseif i > 1 then
								wait(cfg.general.default_delay)
							end

							if not util.isEmpty(line) then
								sampProcessChatInput(line)
							end

							i = i + 1
						end
					end)
					menu.render[0] = false
					table.remove(state.menus, i)
				end

				if i % 2 ~= 0 then
					imgui.SameLine()
				end
			end
			imgui.End()
		end
	end
end)

imgui.OnFrame(function()
	return state.renderFastMenu[0]
end, function(player)
	if state.fastMenuPlayerId and sampIsPlayerConnected(state.fastMenuPlayerId) then
		imgui.SetNextWindowSize(imgui.ImVec2(400 * MDS, 250 * MDS), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(
			imgui.ImVec2(state.fastMenuPos.x, state.fastMenuPos.y + 250 / 2 * MDS),
			imgui.Cond.FirstUseEver,
			imgui.ImVec2(0.5, 0.5)
		)

		local nickname = sampGetPlayerNickname(state.fastMenuPlayerId)
		imgui.Begin(u8("Действия над игроком ") .. nickname, state.renderFastMenu)
		if imgui.BeginTabBar("##fastmenu") then
			for _, source in pairs(commandloader.sources) do
				if source.enabled then
					local filtered = {}
					for _, command in pairs(source.commands) do
						if command.enabled and #command.params > 0 and command.params[1].type == "player" then
							table.insert(filtered, command)
						end
					end

					local middleX = imutil.GetMiddleButtonX(2)
					if #filtered > 0 then
						if imgui.BeginTabItem(u8(source.name)) then
							for i, command in ipairs(filtered) do
								if imutil.ButtonWrappedTextCenter(("/%s\n%s"):format(u8(command.name), u8(command.description)), imgui.ImVec2(middleX, 40 * MDS)) then
									print(command.name)
									sampProcessChatInput("/"..command.name.." "..state.fastMenuPlayerId)
								end

								if i % 2 ~= 0 then
									imgui.SameLine()
								end
							end
							imgui.EndTabItem()
						end
					end
				end
			end
			imgui.EndTabBar()
		end
		imgui.End()
	end
end)

function main()
	android:looperPrepare()
	if not isSampLoaded() or not isSampfuncsLoaded() then
		return
	end
	while not isSampAvailable() do
		wait(0)
	end
	while not sampIsLocalPlayerSpawned() do
		wait(0)
	end

	cfg.general.nickname = cfg.general.nickname ~= "" and cfg.general.nickname
		or util.TranslateNick(sampGetPlayerNickname(select(2, sampGetPlayerIdByCharHandle(PLAYER_PED))))

	if cfg.general.rank == "" or cfg.general.rank == nil then
		check_stats = true
		sampSendChat("/stats")
	end
	commandloader.load()
	commandloader.registerCommands()

	sampRegisterChatCommand("mb", function()
		state.renderMainMenu[0] = not state.renderMainMenu[0]
	end)

	android:showToast(
		u8("MonetBinder загружен. %s шаблонов. %s команд."):format(
			commandloader.sourceCount(),
			commandloader.commandCount()
		),
		2
	)

	while true do
		wait(0)
	end
end

require("samp.events").onShowDialog = function(dialogid, style, title, button1, button2, text)
	if dialogid == 235 and check_stats then
		if text:find("{FFFFFF}Организация: {B83434}%[(.-)]") then
			cfg.general.fraction = text:match("{FFFFFF}Организация: {B83434}%[(.-)]")
			state.fractionInput = imgui.new.char[256](u8(cfg.general.fraction))
		end
		if text:find("{FFFFFF}Должность: {B83434}(.+)%((%d+)%)") then
			cfg.general.rank, cfg.general.rank_number =
				text:match("{FFFFFF}Должность: {B83434}(.+)%((%d+)%)(.+)Уровень розыска")
			state.rankInput = imgui.new.char[256](u8(cfg.general.rank))
			state.rankNumberInput = imgui.new.int(cfg.general.rank_number - 1)
		else
			sampAddChatMessage(
				"[MonetBinder] Не удалось обнаружить вашу должность.",
				-1
			)
		end

		sampSendDialogResponse(235, 0, 0, 0)
		check_stats = false
		return false
	end
end

function generateUsage(cmd, params)
	local usage = "/" .. cmd
	for _, v in ipairs(params) do
		local bracket = v.required and "<" or "["
		usage = usage .. " " .. bracket .. v.name .. (not v.required and "]" or ">")
	end
	return usage
end

---Author: Chapo
function darkTheme()
	imgui.SwitchContext()
	--==[ STYLE ]==--
	imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
	imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
	imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
	imgui.GetStyle().IndentSpacing = 0
	imgui.GetStyle().ScrollbarSize = 10
	imgui.GetStyle().GrabMinSize = 10
	local scsize = imgui.GetStyle().ScrollbarSize
	imgui.GetStyle().ScrollbarSize = scsize + scsize / 2

	--==[ BORDER ]==--
	imgui.GetStyle().WindowBorderSize = 1
	imgui.GetStyle().ChildBorderSize = 1
	imgui.GetStyle().PopupBorderSize = 1
	imgui.GetStyle().FrameBorderSize = 1
	imgui.GetStyle().TabBorderSize = 1

	--==[ ROUNDING ]==--
	imgui.GetStyle().WindowRounding = 5
	imgui.GetStyle().ChildRounding = 5
	imgui.GetStyle().FrameRounding = 5
	imgui.GetStyle().PopupRounding = 5
	imgui.GetStyle().ScrollbarRounding = 5
	imgui.GetStyle().GrabRounding = 5
	imgui.GetStyle().TabRounding = 5

	--==[ ALIGN ]==--
	imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
	imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
	imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)

	--==[ COLORS ]==--
	imgui.GetStyle().Colors[imgui.Col.Text] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.50, 0.50, 0.50, 1.00)
	imgui.GetStyle().Colors[imgui.Col.WindowBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ChildBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PopupBg] = imgui.ImVec4(0.07, 0.07, 0.07, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Border] = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
	imgui.GetStyle().Colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
	imgui.GetStyle().Colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TitleBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.00, 0.00, 0.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.51, 0.51, 0.51, 1.00)
	imgui.GetStyle().Colors[imgui.Col.CheckMark] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.21, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.41, 0.41, 0.41, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Header] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
	imgui.GetStyle().Colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
	imgui.GetStyle().Colors[imgui.Col.Separator] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.ResizeGrip] = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
	imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
	imgui.GetStyle().Colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
	imgui.GetStyle().Colors[imgui.Col.Tab] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TabHovered] = imgui.ImVec4(0.28, 0.28, 0.28, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TabActive] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.07, 0.10, 0.15, 0.97)
	imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.14, 0.26, 0.42, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
	imgui.GetStyle().Colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(1.00, 0.00, 0.00, 0.35)
	imgui.GetStyle().Colors[imgui.Col.DragDropTarget] = imgui.ImVec4(1.00, 1.00, 0.00, 0.90)
	imgui.GetStyle().Colors[imgui.Col.NavHighlight] = imgui.ImVec4(0.26, 0.59, 0.98, 1.00)
	imgui.GetStyle().Colors[imgui.Col.NavWindowingHighlight] = imgui.ImVec4(1.00, 1.00, 1.00, 0.70)
	imgui.GetStyle().Colors[imgui.Col.NavWindowingDimBg] = imgui.ImVec4(0.80, 0.80, 0.80, 0.20)
	imgui.GetStyle().Colors[imgui.Col.ModalWindowDimBg] = imgui.ImVec4(0.00, 0.00, 0.00, 0.70)
end

function onScriptTerminate(script, quitGame)
	if script == thisScript() then
		jsoncfg.save(cfg, "MonetBinder", ".json")
	end
end
