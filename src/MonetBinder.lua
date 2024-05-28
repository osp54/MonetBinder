local version = "%VERSION%"

script_name("MonetBinder v" .. version)
script_author("OSPx")
script_description([[
	A functional binder in Lua for Arizona RP Mobile utilizing the MonetLoader Runtime
	������������������� ������ �� Lua ��� Arizona RP Mobile
]])
script_url("https://github.com/osp54/MonetBinder")
script_version(version)

ffi = require("ffi")
lfs = require("lfs")
imgui = require("mimgui")

encoding = require("encoding")
encoding.default = "CP1251"
u8 = encoding.UTF8

jsoncfg = require("lib.jsoncfg")

util = require("src.util")
imutil = require("src.imgui_util")
doubleclickped = require("src.doubleclickped")
commandloader = require("src.commandloader")

fa = require("fAwesome6_solid")

cfg = {
	general = {
		default_delay = 1000,
		nickname = "",
		fraction = "",
		rank = "",
		rank_number = 0,
		sex = "�������",
	},
	features = {
		fast_menu = true,
	},
	ui = {
		theme = 0,
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

	state.fastMenuEnabled = imgui.new.bool(cfg.features.fast_menu)
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
	state.monetBinderButtonMove = imgui.new.bool(false)

	state.theme = imgui.new.int(cfg.ui.theme)

	state.selectedProfile = 0
	state.currentMsource = nil
	state.currentCommand = nil

	--- @type Menu[]
	state.menus = {}

	--- @type Note[]
	state.openedNotes = {}

	return state
end

local allowedLuaDoc = {
	{
		is_function = true,
		name = "assert",
		description = "�������� ������, ���� ������� �����",
		params = { "condition", "message" },
	},
	{
		is_function = true,
		name = "error",
		description = "�������� ������",
		params = { "message" },
	},
	{
		is_function = true,
		name = "ipairs",
		description = "���������� �������� ��� �������� ������� � ������� ����������� �������",
		params = { "t" },
	},
	{
		is_function = true,
		name = "next",
		description = "���������� ��������� ������� �������",
		params = { "table", "index" },
	},
	{
		is_function = true,
		name = "pairs",
		description = "���������� �������� ��� �������� ������� � ��������� �������",
		params = { "t" },
	},
	{
		is_function = true,
		name = "pcall",
		description = "�������� ������� � ���������� ������",
		params = { "function", "..." },
	},
	{
		is_function = true,
		name = "select",
		description = "���������� ��� ��������� �������, ������� � �������",
		params = { "index", "..." },
	},
	{
		is_function = true,
		name = "tonumber",
		description = "����������� ������ � �����",
		params = { "e", "base" },
	},
	{
		is_function = true,
		name = "tostring",
		description = "����������� �������� � ������",
		params = { "e" },
	},
	{
		is_function = true,
		name = "type",
		description = "���������� ��� ��������",
		params = { "v" },
	},
	{
		is_function = true,
		name = "unpack",
		description = "������������� ������ � ������ ��������",
		params = { "list", "i", "j" },
	},
	{
		is_function = true,
		name = "xpcall",
		description = "�������� ������� � ���������� ������",
		params = { "function", "msgh", "..." },
	},
	{
		is_module = true,
		name = "coroutine",
		description = "������ ��� ������ � ����������",
		doc = {
			{
				is_function = true,
				name = "create",
				description = "������� ����� ��������",
				params = { "f" },
			},
			{
				is_function = true,
				name = "resume",
				description = "��������� ��������",
				params = { "co", "..." },
			},
			{
				is_function = true,
				name = "running",
				description = "���������� ������� ��������",
			},
			{
				is_function = true,
				name = "status",
				description = "���������� ������ ��������",
				params = { "co" },
			},
			{
				is_function = true,
				name = "wrap",
				description = "������� ���������� �������",
				params = { "f" },
			},
			{
				is_function = true,
				name = "yield",
				description = "���������������� ��������",
				params = { "..." },
			},
		},
	},
	{
		is_module = true,
		name = "math",
		description = "������ ��� �������������� ��������",
		doc = {
			{
				is_function = true,
				name = "abs",
				description = "������ �����",
				params = { "x" },
			},
			{
				is_function = true,
				name = "acos",
				description = "����������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "asin",
				description = "��������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "atan",
				description = "����������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "atan2",
				description = "���������� ���� ����������",
				params = { "y", "x" },
			},
			{
				is_function = true,
				name = "ceil",
				description = "���������� �����",
				params = { "x" },
			},
			{
				is_function = true,
				name = "cos",
				description = "�������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "cosh",
				description = "��������������� �������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "deg",
				description = "����������� ������� � �������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "exp",
				description = "����������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "fmod",
				description = "������� �� �������",
				params = { "x", "y" },
			},
			{
				is_function = true,
				name = "floor",
				description = "���������� ����",
				params = { "x" },
			},
			{
				is_function = true,
				name = "frexp",
				description = "��������� ����� �� �������� � ����������",
				params = { "x" },
			},
			{
				is_const = true,
				name = "huge",
				description = "�������������",
			},
			{
				is_function = true,
				name = "ldexp",
				description = "��������� ����� �� 2 � �������",
				params = { "m", "e" },
			},
			{
				is_function = true,
				name = "log",
				description = "����������� ��������",
				params = { "x", "base" },
			},
			{
				is_function = true,
				name = "log10",
				description = "���������� ��������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "max",
				description = "������������ �����",
				params = { "x", "..." },
			},
			{
				is_function = true,
				name = "min",
				description = "����������� �����",
				params = { "x", "..." },
			},
			{
				is_function = true,
				name = "modf",
				description = "����� � ������� ����� �����",
				params = { "x" },
			},
			{
				is_const = true,
				name = "pi",
				description = "����� ��",
			},
			{
				is_function = true,
				name = "pow",
				description = "���������� � �������",
				params = { "x", "y" },
			},
			{
				is_function = true,
				name = "rad",
				description = "����������� ������� � �������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "random",
				description = "��������� �����",
				params = { "m", "n" },
			},
			{
				is_function = true,
				name = "sin",
				description = "�����",
				params = { "x" },
			},
			{
				is_function = true,
				name = "sinh",
				description = "��������������� �����",
				params = { "x" },
			},
			{
				is_function = true,
				name = "sqrt",
				description = "���������� ������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "tan",
				description = "�������",
				params = { "x" },
			},
			{
				is_function = true,
				name = "tanh",
				description = "��������������� �������",
				params = { "x" },
			},
		},
	},
	{
		is_module = true,
		name = "os",
		description = "������ ��� ������ � ������������ ��������",
		doc = {
			{
				is_function = true,
				name = "clock",
				description = "����� ������ ���������",
			},
			{
				is_function = true,
				name = "difftime",
				description = "������� ����� ��������",
				params = { "t2", "t1" },
			},
			{
				is_function = true,
				name = "time",
				description = "������� �����",
			},
		},
	},
	{
		is_module = true,
		name = "string",
		description = "������ ��� ������ �� ��������",
		doc = {
			{
				is_function = true,
				name = "byte",
				description = "���������� �������� �������� �������",
				params = { "s", "i", "j" },
			},
			{
				is_function = true,
				name = "char",
				description = "���������� ������ �� ����",
				params = { "..." },
			},
			{
				is_function = true,
				name = "find",
				description = "����� ���������",
				params = { "s", "pattern", "init", "plain" },
			},
			{
				is_function = true,
				name = "format",
				description = "�������������� ������",
				params = { "formatstring", "..." },
			},
			{
				is_function = true,
				name = "gmatch",
				description = "�������� ��� ������ ���������",
				params = { "s", "pattern" },
			},
			{
				is_function = true,
				name = "gsub",
				description = "������ ���������",
				params = { "s", "pattern", "repl", "n" },
			},
			{
				is_function = true,
				name = "len",
				description = "����� ������",
				params = { "s" },
			},
			{
				is_function = true,
				name = "lower",
				description = "����������� ������ � ������ �������",
				params = { "s" },
			},
			{
				is_function = true,
				name = "match",
				description = "����� ���������",
				params = { "s", "pattern", "init" },
			},
			{
				is_function = true,
				name = "reverse",
				description = "�������������� ������",
				params = { "s" },
			},
			{
				is_function = true,
				name = "sub",
				description = "���������� ���������",
				params = { "s", "i", "j" },
			},
			{
				is_function = true,
				name = "upper",
				description = "����������� ������ � ������� �������",
				params = { "s" },
			},
		},
	},
	{
		is_module = true,
		name = "table",
		description = "������ ��� ������ � ���������",
		doc = {
			{
				is_function = true,
				name = "insert",
				description = "��������� ������� � �������",
				params = { "t", "pos", "value" },
			},
			{
				is_function = true,
				name = "maxn",
				description = "���������� ������������ ������ �������",
				params = { "t" },
			},
			{
				is_function = true,
				name = "remove",
				description = "������� ������� �� �������",
				params = { "t", "pos" },
			},
			{
				is_function = true,
				name = "sort",
				description = "��������� �������",
				params = { "t", "comp" },
			},
		},
	},
}

CHAT_PREFIX = "{00BFFF}[MonetBinder] "
MAIN_CHAT_COLOR = "{FFFF00}"
ERROR_CHAT_COLOR = "{FF0000}"
WARNING_CHAT_COLOR ="{FFA500}"

MDS = MONET_DPI_SCALE or 1
SOURCES_META_URL = "https://raw.githubusercontent.com/osp54/MonetBinder/main/sourcesmeta.json"
cfg = jsoncfg.load(cfg, "MonetBinder", ".json") or cfg

-- compatibility with old versions
if type(cfg.ui.theme) ~= "number" then
	cfg.ui.theme = 0
end

state = mimguiState()

doubleclickped.onDoubleClickedPed = function(ped, x, y)
	if not state.fastMenuEnabled[0] then
		return
	end

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

function chat_info(msg, ...)
	sampAddChatMessage(CHAT_PREFIX .. MAIN_CHAT_COLOR .. string.format(msg, ...), -1)
end
function chat_error(msg, ...)
	sampAddChatMessage(CHAT_PREFIX .. ERROR_CHAT_COLOR .. string.format(msg, ...), -1)
end
function chat_warning(msg, ...)
	sampAddChatMessage(CHAT_PREFIX .. WARNING_CHAT_COLOR .. string.format(msg, ...), -1)
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	fa.Init(14 * MDS)
	imgui.GetStyle():ScaleAllSizes(MDS)
	
	if cfg.ui.theme == 0 then
		grayTheme()
	else
		darkTheme()
	end
end)


local function textEdit(lbl, text, command)
	imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
	imgui.InputTextMultiline(
		lbl,
		text,
		15360,
		imgui.ImVec2(0, imgui.GetWindowHeight() - 70 * MDS - imgui.GetStyle().FramePadding.y * 2)
	)

	function appendText(atext)
		local rtext = u8:decode(ffi.string(text))
		rtext = rtext .. atext
		ffi.copy(text, u8(rtext))
	end

	imgui.SetCursorPosY(imgui.GetWindowHeight() - 30 * MDS - imgui.GetStyle().FramePadding.y * 2)
	if
		imgui.Button(
			fa.TAGS .. u8(" ����������/�������"),
			imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)
		)
	then
		imgui.OpenPopup(u8("����������/�������"))
	end

	if
		imgui.BeginPopupModal(
			u8("����������/�������"),
			_,
			imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
		)
	then
		imgui.SetWindowSizeVec2(imgui.ImVec2(700 * MDS, 400 * MDS))
		imgui.BeginChild("##tags",
			imgui.ImVec2(0,
				imgui.GetWindowSize().y - 30 * MDS - imgui.GetCursorPosY() - imgui.GetStyle().FramePadding.y * 2), true)

		imutil.CenterText(
			u8(
				"����������, ������� ����� ������������ � ������:"
			)
		)
		for k, v in pairs(cfg.general) do
			if imgui.Button(u8("~{%s}~ -- %s"):format(k, u8(v)), imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)) then
				appendText(u8("\n~{%s}~"):format(k))
			end
			imgui.Separator()
		end

		if command and #command.params > 0 then
			imutil.CenterText(u8("���������:"))
			for i, param in pairs(command.params) do
				local label = u8("~{%s}~"):format(ffi.string(param.name))
				if imgui.Button(label, imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)) then
					appendText("\n" .. label)
				end
				imgui.Separator()
			end
		end

		if command and #command.menus > 0 then
			imutil.CenterText(u8("����:"))
			for i, menu in pairs(command.menus) do
				local label = u8("~{openMenu(\"%s\")}~"):format(ffi.string(menu.name))
				if imgui.Button(label, imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)) then
					appendText("\n" .. label)
				end
				imgui.Separator()
			end
		end

		imutil.CenterText(
			u8(
				"�������, ������� ����� ������������ � ������:"
			)
		)
		for i, doc in ipairs(commandloader.env_docs) do
			local params = #doc.params > 0 and "(" .. table.concat(doc.params, ", ") .. ")" or "()"
			if
				imutil.ButtonWrappedTextCenter(
					u8("~{%s%s}~\n%s"):format(doc.name, u8(params), u8(doc.description)),
					imgui.ImVec2(imutil.GetMiddleButtonX(1), 45 * MDS)
				)
			then
				local paste = #doc.params > 0 and doc.paste or "~{" .. doc.name .. "()" .. "}~"
				appendText("\n" .. paste)
			end
			imgui.Separator()
		end

		if imgui.CollapsingHeader(u8("��������� ������� Lua")) then
			if
				imgui.Button(
					fa.LINK .. u8(" ������� ������������ Lua"),
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
						imutil.CenterText(u8("������: %s"):format(fullKey))
						imutil.CenterText(u8(v.description))
						processAllowedLuaDoc(v.doc, fullKey)
					end
				end
			end

			processAllowedLuaDoc(allowedLuaDoc)
		end

		imgui.EndChild()
		if
			imgui.Button(
				fa.XMARK .. u8(" �������"),
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
			fa.XMARK .. u8(" �������"),
			imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)
		)
	then
		imgui.CloseCurrentPopup()
	end
end
local mainMenu = imgui.OnFrame(function()
	return state.renderMainMenu[0]
end, function(player)
	local screenX, screenY = getScreenResolution()

	imgui.SetNextWindowSize(imgui.ImVec2(700 * MDS, 400 * MDS), imgui.Cond.FirstUseEver)
	imgui.SetNextWindowPos(imgui.ImVec2(screenX / 2, screenY / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	imgui.Begin(u8("MonetBinder"), state.renderMainMenu)
	state.mainMenuMenuPos = imgui.GetWindowPos()

	imgui.BeginTabBar("##tabbar")
	if imgui.BeginTabItem(u8("����� ���������")) then
		imutil.Setting(
			u8("��������"),
			u8("�������� (��): %d"):format(state.defaultDelayInput[0]),
			function()
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputInt("##defaultdelay", state.defaultDelayInput, 0)
			end
		)
		imutil.Setting(
			u8("���� �� ���"),
			u8("���� �� ���: %s"):format(ffi.string(state.nicknameInput)),
			function()
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputText("##nickname", state.nicknameInput, 256)
			end
		)
		if imutil.SettingButton(u8("��� ���: %s"):format(u8(cfg.general.sex))) then
			if cfg.general.sex == "�������" then
				cfg.general.sex = "�������"
			elseif cfg.general.sex == "�������" then
				cfg.general.sex = "�������"
			else
				check_stats = true
				sampSendChat("/stats")
			end
		end
		imutil.Setting(
			u8("���� �������"),
			u8("���� �������: %s"):format(ffi.string(state.fractionInput)),
			function()
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputText("##fraction", state.fractionInput, 256)
			end
		)
		imutil.Setting(
			u8("��� ����"),
			u8("��� ����: %s (%d)"):format(ffi.string(state.rankInput), state.rankNumberInput[0] + 1),
			function()
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputText("##rank", state.rankInput, 256)
				imutil.CenterText(u8("����� �����:"))
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.Combo("##ranknumber", state.rankNumberInput, state.ImRanks, #state.ranks)
			end
		)
		if imutil.ToggleButton(u8(" ������ MonetBinder"), state.monetBinderButton) then
			cfg.ui.monet_binder_button = state.monetBinderButton[0]
		end
		imgui.SameLine()
		imgui.SetCursorPosX(imgui.GetWindowWidth() / 2 - imgui.GetStyle().FramePadding.x * 2)
		if imutil.ToggleButton(u8(" ����������� ������"), state.monetBinderButtonMove) then
			cfg.ui.monet_binder_button_move = state.monetBinderButtonMove[0]
		end
		if imutil.ToggleButton(u8"����-���� �� ��������-�����", state.fastMenuEnabled) then
			cfg.features.fast_menu = state.fastMenuEnabled[0]
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
				fa.WAND_SPARKLES .. u8(" ��������� �������������"),
				imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)
			)
		then
			check_stats = true
			sampSendChat("/stats")
		end
		imgui.EndTabItem()
	end

	if imgui.BeginTabItem(u8("�������, �������")) then
		imgui.BeginChild(
			"##profiles-vertical-choose",
			imgui.ImVec2((imgui.GetWindowWidth() * 0.35) - imgui.GetStyle().FramePadding.x * 2, 0),
			true
		)
		if imgui.Button(fa.CIRCLE_PLUS .. u8(" ������� �������"), imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
			table.insert(commandloader.sources, commandloader.newSource())
			state.selectedProfile = #commandloader.sources
			state.currentMsource = commandloader.imserializer.serSource(commandloader.sources[state.selectedProfile])
		end
		imgui.SameLine()
		if imgui.Button(fa.GLOBE .. u8(" �������"), imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
			imgui.OpenPopup(u8("������� ��������"))
		end
		if
			imgui.BeginPopupModal(
				u8("������� ��������"),
				_,
				imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
			)
		then
			imgui.SetWindowSizeVec2(imgui.ImVec2(700 * MDS, 400 * MDS))
			if
				imgui.Button(
					fa.ARROWS_ROTATE .. u8(" ������������� ������"),
					imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)
				)
			then
				state.sources_meta = nil
				state.sources_meta_loading = false
			end
			imgui.BeginChild("##browser", imgui.ImVec2(0, imgui.GetWindowSize().y - 30 * MDS - imgui.GetCursorPosY() - imgui.GetStyle().FramePadding.y * 2), true)

			if state.sources_meta and state.sources_meta.error then
				imgui.SetCursorPosY(imgui.GetWindowHeight() / 2)
				imutil.CenterError(u8("������ ��������: %s"):format(state.sources_meta.error))
			end

			if state.sources_meta and not state.sources_meta.error then
				imgui.Columns(4, "##sources", true)
				imutil.CenterColumnText(u8("���"))
				imgui.NextColumn()
				imutil.CenterColumnText(u8("��������"))
				imgui.NextColumn()
				imutil.CenterColumnText(u8("�����"))
				imgui.NextColumn()
				imutil.CenterColumnText(u8("��������"))
				imgui.NextColumn()
				imgui.Separator()
				for i, source in ipairs(state.sources_meta) do
					if not source.exsource then
						source.exsource = commandloader.findSourceByName(u8:decode(source.name)) or {}
					end
					if source.error then
						imgui.Columns(1)
						imutil.CenterError(u8("������ ��������: %s"):format(source.error))
						imgui.Columns(4, "##sources", true)
					elseif source.download_progress_percent then
						imgui.Columns(1)
						imgui.ProgressBar(source.download_progress_percent / 100, imgui.ImVec2(-1, 15 * MDS))
						imgui.Columns(4, "##sources", true)

						if source.downloaded_at and source.downloaded_at + 1 < os.time() then
							source.downloaded_at = nil
							source.download_progress_percent = nil
							source.downloaded = nil
							state.sources_meta = nil
							state.sources_meta_loading = false
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
							(source.exsource.name and fa.ARROWS_ROTATE or fa.DOWNLOAD) .. "##" .. i,
							imgui.ImVec2(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x, 30 * MDS)
						)
					then
						local filename = source.download_link:match("([^/]+)$")
						local filepath = source.exsource.name and source.exsource.filepath or util.path_join(getWorkingDirectory(), commandloader.dir, filename)
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
				imutil.CenterText(fa.SPINNER .. u8(" ��������..."))
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

			imgui.EndChild()
			if imgui.Button(fa.XMARK .. u8(" �������"), imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)) then
				imgui.CloseCurrentPopup()
			end
			imgui.EndPopup()
		end
		for i, source in pairs(commandloader.sources) do
			imgui.BeginGroup()
			if imgui.Button(
				u8(source.name),
				imgui.ImVec2(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2, 30 * MDS)
			) then
				state.selectedProfile = i
				state.currentMsource = commandloader.imserializer.serSource(source)
			end
			imgui.SameLine()
			if imgui.Button(fa.TRASH, imgui.ImVec2(imutil.GetMiddleButtonX(3), 30 * MDS)) then
				imgui.OpenPopup(u8("�������� �������"))
			end
			if imutil.ConfirmationPopup(u8("�������� �������"), u8("�� �������?")) then
				commandloader.removeSource(source)
				commandloader.sources[i] = nil

				state.currentMsource = nil
				state.selectedProfile = 0
			end
			imgui.EndGroup()
		end
		imgui.EndChild()
		imgui.SameLine()
		imgui.BeginChild("##profile", imgui.ImVec2(0, 0), true)
		local source = commandloader.sources[state.selectedProfile]
		if source and state.currentMsource then
			if imgui.Button(fa.TRASH, imgui.ImVec2(imutil.GetMiddleButtonX(4), 30 * MDS)) then
				imgui.OpenPopup(u8("�������� �������"))
			end
			if imutil.ConfirmationPopup(u8("�������� �������"), u8("�� �������?")) then
				commandloader.removeSource(source)
				commandloader.sources[state.selectedProfile] = nil

				state.currentMsource = nil
				state.selectedProfile = 0
			end
			if not state.currentMsource then
				imgui.EndChild()
				imgui.EndTabItem()
				return
			end

			imgui.SameLine()
			if imgui.Button(fa.FLOPPY_DISK, imgui.ImVec2(imutil.GetMiddleButtonX(4), 30 * MDS)) then
				commandloader.sources[state.selectedProfile] = commandloader.imserializer.deserSource(state.currentMsource)
				commandloader.saveSource(commandloader.sources[state.selectedProfile])
				commandloader.reload()

				imutil.addNotification(u8("������� ��������"), 1.0)
			end
			imgui.SameLine()
			if imgui.Button(fa.COPY, imgui.ImVec2(imutil.GetMiddleButtonX(4), 30 * MDS)) then
				local source = commandloader.imserializer.deserSource(state.currentMsource)
				setClipboardText(encodeJson(source))

				imutil.addNotification(u8("������� ���������� � ����� ������"), 1.0)
			end
			imgui.SameLine()
			if
				imutil.ToggleButtonIcon(
					fa.TOGGLE_ON,
					fa.TOGGLE_OFF,
					state.currentMsource.enabled[0],
					imgui.ImVec2(imutil.GetMiddleButtonX(4), 30 * MDS)
				)
			then
				state.currentMsource.enabled[0] = not state.currentMsource.enabled[0]
			end

			imgui.Separator()
			imutil.Setting(u8("���, �����"), u8("���, �����: %s, %s"):format(ffi.string(state.currentMsource.name), ffi.string(state.currentMsource.author)), function()
				imutil.CenterText(u8("���:"))
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputText("##name", state.currentMsource.name, 256)
				imutil.CenterText(u8("�����:"))
				imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
				imgui.InputText("##author", state.currentMsource.author, 256)
			end)
			imgui.Separator()
			imutil.Setting(
				u8("��������"),
				imutil.shortifyText(u8("��������: %s"):format(ffi.string(state.currentMsource.description))),
				function()
					imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
					imgui.InputText(
						"##description",
						state.currentMsource.description,
						256
					)
				end
			)
			if state.currentMsource.commandsTab == nil then
				state.currentMsource.commandsTab = imgui.new.int(1);
			end
			imutil.ItemSelector(u8 '##commandsornotes',
				{
					u8 '������� ' .. "(" .. #state.currentMsource.commands .. ")",
					u8 '������� ' .. "(" .. #state.currentMsource.notes .. ")"
				},
				state.currentMsource.commandsTab,
				imgui.GetWindowWidth() / 2 - imgui.GetStyle().FramePadding.x * 3
			)
			if state.currentMsource.commandsTab[0] == 1 then
				if
					imgui.Button(
						fa.CIRCLE_PLUS .. u8(" ������� �������"),
						imgui.ImVec2(imutil.GetMiddleButtonX(1), 25 * MDS)
					)
				then
					table.insert(state.currentMsource.commands, commandloader.imserializer.newCommand({
						name = imgui.new.char[256]("cmd" .. #state.currentMsource.commands + 1)
					}))
				end
				imgui.BeginChild("##commands", imgui.ImVec2(0, 0), true)
				
				imgui.Columns(3, "##commands", true)
				imutil.CenterColumnText(u8("�������"))
				imgui.NextColumn()
				imutil.CenterColumnText(u8("��������"))
				imgui.NextColumn()
				imutil.CenterColumnText(u8("��������"))
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
							imgui.ImVec2(imutil.GetMiddleColumnX(3), 25 * MDS)
						)
					then
						command.enabled[0] = not command.enabled[0]
					end
					imgui.SameLine()
					if imgui.Button(fa.TRASH .. "##" .. i, imgui.ImVec2(imutil.GetMiddleColumnX(3), 25 * MDS)) then
						imgui.OpenPopup(u8("�������� �������##"..i))
					end
					if imutil.ConfirmationPopup(u8("�������� �������##"..i), u8("�� �������?")) then
						table.remove(state.currentMsource.commands, i)
					end
					imgui.SameLine()
					if imgui.Button(fa.PEN .. "##" .. i, imgui.ImVec2(imutil.GetMiddleColumnX(3), 25 * MDS)) then
						state.currentCommand = i
						imgui.OpenPopup(u8("�������������� �������##"..i))
					end
					imgui.NextColumn()
					imgui.Separator()
				end
				if	state.currentCommand and
					imgui.BeginPopupModal(
						u8("�������������� �������##"..state.currentCommand),
						_,
						imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
					)
				then
					local command = state.currentMsource.commands[state.currentCommand]

					imgui.SetWindowSizeVec2(imgui.ImVec2(700 * MDS, 400 * MDS))
					imgui.BeginChild("##command", imgui.ImVec2(0, imgui.GetWindowSize().y - 30 * MDS - imgui.GetCursorPosY() - imgui.GetStyle().FramePadding.y * 2), true)
					if util.isEmpty(ffi.string(command.name)) then
						imutil.CenterError("��� ������� �� ����� ���� ������")
					end
					imutil.Setting(
						u8("��������"),
						u8("��������: %s"):format(ffi.string(command.name)),
						function()
							imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
							imgui.InputText("##commandname", command.name, 256)
						end
					)
					imgui.Separator()
					imutil.Setting(
						u8("��������"),
						u8("��������: %s"):format(ffi.string(command.description)),
						function()
							imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
							imgui.InputText("##commanddescription", command.description, 256)
						end
					)
					imgui.Separator()

					if util.isEmpty(ffi.string(command.text)) then
						imutil.CenterError(u8("����� ������� �� ����� ���� ������"))
					end

					imutil.Setting(
						u8("�����"),
						imutil.shortifyText(u8("�����: %s"):format(ffi.string(command.text):gsub("\n", ""))),
						function()
							imgui.SetWindowSizeVec2(imgui.ImVec2(600 * MDS, 300 * MDS))
							textEdit("texteditcmdtext"..state.currentCommand, command.text, command)
						end,
						false
					)

					if #command.params > 0 then
						imutil.CenterText(u8("���������"))
						imgui.Separator()
						imgui.Columns(4, "##params", true)
						imgui.Text(u8("��������"))
						imgui.NextColumn()
						imgui.Text(u8("���"))
						imgui.NextColumn()
						imgui.Text(u8("�� ���������"))
						imgui.NextColumn()
						imgui.Text(u8("��������"))
						imgui.NextColumn()
						imgui.Separator()

						for i, param in pairs(command.params) do
							if not param.ImTypes then
								param.types = {}
								param.originalTypes = {}
								param.selectedType = imgui.new.int(0)
								local i = 0
								for k, v in pairs(commandloader.rusTypes) do
									table.insert(param.originalTypes, k)
									table.insert(param.types, v)
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
									imgui.ImVec2(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2, 25 * MDS)
								)
							then
								imgui.OpenPopup(u8("�������� ���������##"..i))
							end
							if imutil.ConfirmationPopup(u8("�������� ���������##"..i), u8("�� �������?")) then
								table.remove(command.params, i)
							end
							imgui.NextColumn()
							imgui.Separator()
						end
						imgui.Columns(1)
					end
					if
						imgui.Button(
							fa.CIRCLE_PLUS .. u8(" �������� ��������"),
							imgui.ImVec2(imutil.GetMiddleButtonX(1), 25 * MDS)
						)
					then
						table.insert(command.params, commandloader.imserializer.newParam({
							name = imgui.new.char[256]("param" .. #command.params + 1),
						}))
					end
					if #command.menus > 0 then
						imutil.CenterText(u8("����"))
						imgui.Separator()
						imgui.Columns(3, "##menus", true)
						imgui.Text(u8("����"))
						imgui.NextColumn()
						imgui.Text(u8("���"))
						imgui.NextColumn()
						imgui.Text(u8("��������"))
						imgui.NextColumn()
						imgui.Separator()

						for i, menu in pairs(command.menus) do
							if not menu.ImTypes then
								menu.types = {}

								menu.selectedType = imgui.new.int(0)
								local i = 0
								for k, v in pairs(commandloader.menuTypes) do
									table.insert(menu.types, v)
									if ffi.string(menu.type) == v then
										menu.selectedType = imgui.new.int(i)
									end
									i = i + 1
								end
								menu.ImTypes = imgui.new["const char*"][#menu.types](menu.types)
							end
							imgui.SetNextItemWidth(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2)
							imgui.InputText("##menuname" .. i, menu.name, 256)
							imgui.NextColumn()
							imgui.SetNextItemWidth(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2)
							imgui.Combo("##menutype" .. i, menu.selectedType, menu.ImTypes, #menu.types)
							imgui.NextColumn()
							if
								imgui.Button(
									fa.TRASH .. "##menu" .. i,
									imgui.ImVec2(imutil.GetMiddleColumnX(2), 25 * MDS)
								)
							then
								imgui.OpenPopup(u8("�������� ����##"..i))
							end
							if imutil.ConfirmationPopup(u8("�������� ����##"..i), u8("�� �������?")) then
								table.remove(command.menus, i)
							end
							imgui.SameLine()
							if
								imgui.Button(
									fa.PEN .. "##menu" .. i,
									imgui.ImVec2(imutil.GetMiddleColumnX(2), 25 * MDS)
								)
							then
								state.currentMenu = i
								imgui.OpenPopup(u8("�������������� ����").."##menu"..i)
							end

							if imgui.BeginPopupModal(
								u8("�������������� ����".."##menu"..i),
								_,
								imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
							) then
								local menu = state.currentMsource.commands[state.currentCommand].menus[state.currentMenu]
								imgui.SetWindowSizeVec2(imgui.ImVec2(700 * MDS, 400 * MDS))
								imgui.BeginChild("##textedit", imgui.ImVec2(0, imgui.GetWindowSize().y - 30 * MDS - imgui.GetCursorPosY() - imgui.GetStyle().FramePadding.y * 2), true)
								imutil.Setting(
									u8("��������"),
									u8("��������: %s"):format(ffi.string(menu.description)),
									function()
										imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
										imgui.InputText("##menudescription", menu.description, 256)
									end
								)
								imutil.CenterText(u8("������ ����"))
								imgui.Separator()
								local xlbl = u8("������")
								imgui.SetCursorPosX(imgui.GetWindowWidth() / 4 - imgui.CalcTextSize(xlbl).x / 2)
								imgui.Text(xlbl)
								imgui.SameLine()
								local ylbl = u8("������")
								imgui.SetCursorPosX(imgui.GetWindowWidth() / 4 * 3 - imgui.CalcTextSize(ylbl).x / 2)
								imgui.Text(ylbl)

								imgui.SetNextItemWidth(imutil.GetMiddleButtonX(2))
								imgui.SliderInt("##sizex"..state.currentMenu, menu.size.x, 100, 1000)
								imgui.SameLine()
								imgui.SetNextItemWidth(imutil.GetMiddleButtonX(2))
								imgui.SliderInt("##sizey"..state.currentMenu, menu.size.y, 100, 1000)
								imgui.Separator()

								if menu.types[menu.selectedType[0]+1] == commandloader.menuTypes.CHOICE then
									if #menu.choices > 0 then
										imutil.CenterText(u8("�������� ������"))
										imgui.Separator()
										imgui.Columns(3, "##choices", true)
										imgui.Text(u8("�������"))
										imgui.NextColumn()
										imgui.Text(u8("�����"))
										imgui.NextColumn()
										imgui.Text(u8("��������"))
										imgui.NextColumn()
										imgui.Separator()

										for i, choice in pairs(menu.choices) do
											imgui.SetNextItemWidth(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2)
											imgui.InputText("##choicename" .. i, choice.name, 256)
											imgui.NextColumn()
											if imgui.Button(fa.PEN .. "##choice" .. i, imgui.ImVec2(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2, 30 * MDS)) then
												imgui.OpenPopup(u8("�������������� ������ ��������").."##ch"..i)
											end

											if imgui.BeginPopupModal(u8("�������������� ������ ��������").."##ch"..i, _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
												imgui.SetWindowSizeVec2(imgui.ImVec2(600 * MDS, 300 * MDS))
												textEdit("##texteditchoice"..i, choice.text, command)
												imgui.EndPopup()
											end
											
											imgui.NextColumn()
											if
												imgui.Button(
													fa.TRASH .. "##choice" .. i,
													imgui.ImVec2(imgui.GetColumnWidth() - imgui.GetStyle().FramePadding.x * 2, 30 * MDS)
												)
											then
												imgui.OpenPopup(u8("�������� ��������").."##ch"..i)
											end
											if imutil.ConfirmationPopup(u8("�������� ��������").."##ch"..i, u8("�� �������, ��� ������ ������� �������?")) then
												table.remove(menu.choices, i)
											end
											imgui.NextColumn()
											imgui.Separator()
										end
										imgui.Columns(1)
									end
									if
										imgui.Button(
											fa.CIRCLE_PLUS .. u8(" �������� �������"),
											imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)
										)
									then
										table.insert(menu.choices, commandloader.imserializer.newChooseMenuChoice({
											name = imgui.new.char[256]("choice" .. #menu.choices + 1),
										}))
									end
								end

								imgui.EndChild()
								if imgui.Button(fa.FLOPPY_DISK, imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)) then
									imgui.CloseCurrentPopup()
								end
								imgui.EndPopup()
							end

							imgui.NextColumn()
							imgui.Separator()
						end
						imgui.Columns(1)
					end
					if imgui.Button(fa.CIRCLE_PLUS .. u8(" �������� ����"), imgui.ImVec2(imutil.GetMiddleButtonX(1), 25 * MDS)) then
						table.insert(command.menus, commandloader.imserializer.newChooseMenu({
							name = imgui.new.char[256]("menu" .. #command.menus + 1)
						}))
					end
					imgui.EndChild()
					if imgui.Button(fa.XMARK .. u8" �������� ���������", imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
						imgui.OpenPopup(u8"�������� ���������")
					end
					local needClose = false
					if imutil.ConfirmationPopup(u8"�������� ���������", u8"�� �������, ��� ������ �������� ���������?") then
						state.currentMsource.commands[state.currentCommand] = commandloader.imserializer.serCommand(commandloader.sources[state.selectedProfile].commands[state.currentCommand])
						needClose = true
					end
					if needClose then
						imgui.CloseCurrentPopup()
					end
					imgui.SameLine()
					if imgui.Button(fa.FLOPPY_DISK .. u8" ���������", imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
						if not util.isEmpty(ffi.string(command.name)) and not util.isEmpty(ffi.string(command.text)) then
							for _, param in pairs(command.params) do
								param.type = param.originalTypes[param.selectedType[0] + 1]
								param.required = imgui.new.bool(util.isEmpty(ffi.string(param.default)))
							end
							for _, menu in pairs(command.menus) do
								menu.type = menu.types[menu.selectedType[0] + 1]
							end

							commandloader.sources[state.selectedProfile] =
								commandloader.imserializer.deserSource(state.currentMsource)
							commandloader.saveSource(commandloader.sources[state.selectedProfile])
							commandloader.reload()
							imgui.CloseCurrentPopup()
							imutil.addNotification(u8"������� ���������", 1.0)
						else
							imutil.addNotification(u8"��������� ��� ����", 1.0)
						end
					end
					imgui.EndPopup()
				end
				imgui.EndChild()
			else
				if
					imgui.Button(
						fa.CIRCLE_PLUS .. u8(" ������� �������"),
						imgui.ImVec2(imutil.GetMiddleButtonX(1), 25 * MDS)
					)
				then
					table.insert(state.currentMsource.notes, commandloader.imserializer.newNote({
						name = imgui.new.char[256]("note" .. #state.currentMsource.notes + 1)
					}))
				end
				imgui.BeginChild("##notes", imgui.ImVec2(0, 0), true)
				imgui.Columns(2, "##notes", true)
				imutil.CenterColumnText(u8("�������"))
				imgui.NextColumn()
				imutil.CenterColumnText(u8("��������"))
				imgui.NextColumn()
				imgui.Separator()
				for i, note in pairs(state.currentMsource.notes) do
					imgui.Text(ffi.string(note.name))
					imgui.NextColumn()
					if imutil.ToggleButtonIcon(fa.TOGGLE_ON, fa.TOGGLE_OFF, note.enabled[0], imgui.ImVec2(imutil.GetMiddleColumnX(4), 25 * MDS)) then
						note.enabled[0] = not note.enabled[0]
					end
					imgui.SameLine()
					if
						imgui.Button(
							fa.TRASH .. "##note" .. i,
							imgui.ImVec2(imutil.GetMiddleColumnX(4), 25 * MDS)
						)
					then
						imgui.OpenPopup(u8("�������� �������##"..i))
					end
					if imutil.ConfirmationPopup(u8("�������� �������##"..i), u8("�� �������?")) then
						table.remove(state.currentMsource.notes, i)
					end
					imgui.SameLine()
					if imgui.Button(fa.PEN .. "##note" .. i, imgui.ImVec2(imutil.GetMiddleColumnX(4), 25 * MDS)) then
						state.currentNote = i
						imgui.OpenPopup(u8("�������������� �������##"..i))
					end

					if imgui.BeginPopupModal(u8("�������������� �������##"..i), _, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
						local note = state.currentMsource.notes[state.currentNote]
						imgui.SetWindowSizeVec2(imgui.ImVec2(700 * MDS, 400 * MDS))
						imgui.BeginChild("##textedit", imgui.ImVec2(0, imgui.GetWindowSize().y - 30 * MDS - imgui.GetCursorPosY() - imgui.GetStyle().FramePadding.y * 2), true)
						imutil.Setting(
							u8("��������"),
							u8("��������: %s"):format(ffi.string(note.name)),
							function()
								imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
								imgui.InputText("##notename", note.name, 256)
							end
						)
						imutil.Setting(
							u8("�����"),
							imutil.shortifyText(u8("�����: %s"):format(ffi.string(note.text):gsub("\n", ""))),
							function()
								imgui.SetWindowSizeVec2(imgui.ImVec2(600 * MDS, 300 * MDS))
								textEdit("texteditnote"..state.currentNote, note.text)
							end,
							false
						)
						imutil.ToggleButton(u8("��������� ��� ������� �������"), note.openOnStart)
						imgui.SetNextItemWidth(imgui.GetWindowWidth() - imgui.GetStyle().FramePadding.x * 2)
						imgui.SliderFloat("##fps", note.FPS, 0, 60, u8("���-�� ���������� ��-��� � ���: %.1f"))
						imgui.EndChild()
						if imgui.Button(fa.XMARK .. u8" �������� ���������", imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
							imgui.OpenPopup(u8"�������� ���������")
						end
						local needClose = false
						if imutil.ConfirmationPopup(u8"�������� ���������", u8"�� �������, ��� ������ �������� ���������?") then
							state.currentMsource.notes[state.currentNote] = commandloader.imserializer.serNote(commandloader.sources[state.selectedProfile].notes[state.currentNote])
							needClose = true
						end
						if needClose then
							imgui.CloseCurrentPopup()
						end
						imgui.SameLine()
						if imgui.Button(fa.FLOPPY_DISK .. u8(" ���������"), imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
							commandloader.sources[state.selectedProfile] = commandloader.imserializer.deserSource(state.currentMsource)
							commandloader.saveSource(commandloader.sources[state.selectedProfile])

							imutil.addNotification(u8("������� ���������"), 1.0)
							imgui.CloseCurrentPopup()
						end
						imgui.EndPopup()
					end
					imgui.SameLine()
					if imgui.Button(fa.EYE .. "##note" .. i, imgui.ImVec2(imutil.GetMiddleColumnX(4), 25 * MDS)) then
						table.insert(state.openedNotes, util.merge(commandloader.sources[state.selectedProfile].notes[i], {
							profile = state.selectedProfile,
							index = i,
						}))
					end
					imgui.NextColumn()
					imgui.Separator()
				end
				imgui.Columns(1)
				imgui.EndChild()
			end
		else
			imgui.SetCursorPosY(imgui.GetWindowHeight() / 2)
			imutil.CenterText(u8("�������� �������"))
		end
		imgui.EndChild()
		imgui.EndTabItem()
	end
	if imgui.BeginTabItem(u8("����������")) then
		imutil.CenterText(u8("MonetBinder v%s"):format(script.this.version))
		local description = u8("MonetBinder - ������������������� ������ ��� Arizona RP.")
		local descriptionWidth = imgui.CalcTextSize(description).x
		imutil.CenterText(description)
		local copyright = u8("� 2024 OSPx")
		local copyWidth = imgui.CalcTextSize(copyright).x
		local width = imgui.GetWindowWidth()
		
		imgui.SetCursorPosX((width / 2 - descriptionWidth / 2) + descriptionWidth - copyWidth)
		imgui.Text(copyright)
		imgui.Separator()

		imgui.Columns(2, "##info", true)
		imgui.Text(u8("����� �������"))
		imgui.NextColumn()
		imgui.Text(u8("OSPx"))
		imgui.Separator()

		imgui.NextColumn()
		imgui.Text(u8("Telegram �����"))
		imgui.NextColumn()
		if imgui.SmallButton(u8("t.me/monetbinder")) then
			util.openLink("https://t.me/monetbinder")
		end
		imgui.Separator()
		
		imgui.NextColumn()
		imgui.Text(u8("GitHub"))
		imgui.NextColumn()
		if imgui.SmallButton(u8("github.com/osp54/MonetBinder")) then
			util.openLink("https://github.com/osp54/MonetBinder")
		end
		imgui.NextColumn()
		imgui.Separator()
		imgui.Columns(1)

		imutil.CenterText(u8("����� ���� ����������"))
		if imgui.RadioButtonIntPtr(u8("����� ����"), state.theme, 0) then
			state.theme[0] = 0
			cfg.ui.theme = 0
			grayTheme()
		end
		if imgui.RadioButtonIntPtr(u8("������ ����"), state.theme, 1) then
			state.theme[0] = 1
			cfg.ui.theme = 1
			darkTheme()
		end
		

		imgui.EndTabItem()
	end

	imgui.End()
end)

local mb_button = imgui.OnFrame(function()
	return state.monetBinderButton[0]
end, function(player)
	local pos = imgui.ImVec2(cfg.ui.monet_binder_button_pos.x, cfg.ui.monet_binder_button_pos.y)
	local size = imgui.ImVec2(cfg.ui.monet_binder_button_size.x, cfg.ui.monet_binder_button_size.y)
	res, pos, size =
		imutil.BackgroundButton(fa.TERMINAL, state.monetBinderButton, pos, size, nil, state.monetBinderButtonMove[0])

	if res then
		state.renderMainMenu[0] = not state.renderMainMenu[0]
	end

	cfg.ui.monet_binder_button_pos.x = pos.x
	cfg.ui.monet_binder_button_pos.y = pos.y

	cfg.ui.monet_binder_button_size.x = size.x
	cfg.ui.monet_binder_button_size.y = size.y
end)

local notes_renderer = imgui.OnFrame(function()
	return state.openedNotes and #state.openedNotes > 0
end, function (player)
	for i, note in ipairs(state.openedNotes) do
		imgui.SetNextWindowSize(imgui.ImVec2(note.size.x * MDS, note.size.y * MDS), imgui.Cond.FirstUseEver)
		imgui.SetNextWindowPos(
			imgui.ImVec2(note.pos.x, note.pos.y),
			imgui.Cond.FirstUseEver,
			imgui.ImVec2(0.5, 0.5)
		)
		local pos = imgui.GetWindowPos()
		local size = imgui.GetWindowSize()

		local flag = note.pinned and imgui.WindowFlags.NoTitleBar
								+ imgui.WindowFlags.NoResize
								+ imgui.WindowFlags.NoMove
								+ imgui.WindowFlags.NoBackground
								or imgui.WindowFlags.NoTitleBar
		imgui.Begin(u8(note.name), imgui.new.bool(true), flag)
		imgui.BeginChild("##note", imgui.ImVec2(0, imgui.GetWindowSize().y - 15 * MDS - imgui.GetCursorPosY() - imgui.GetStyle().FramePadding.y * 2), true)
		imgui.TextWrapped(u8(note.formattedText or note.text))
		imgui.EndChild()
		if imgui.Button(fa.XMARK, imgui.ImVec2(imutil.GetMiddleButtonX(2), 15 * MDS)) then
			table.remove(state.openedNotes, i)
		end
		imgui.SameLine()
		if imgui.Button((note.pinned and u8"���������" or u8"���������"), imgui.ImVec2(imutil.GetMiddleButtonX(2), 15 * MDS)) then
			note.pinned = not note.pinned
		end
		imgui.End()

		local function isPosOrSizeChanged()
			return pos.x ~= note.pos.x or pos.y ~= note.pos.y or size.x ~= note.size.x or size.y ~= note.size.y
		end

		if isPosOrSizeChanged() then
			print(note.profile)
			print(note.index)
			local dn = commandloader.sources[note.profile].notes[note.index]

			note.pos.x = pos.x
			note.pos.y = pos.y
			note.size.x = size.x
			note.size.y = size.y

			dn.pos = note.pos
			dn.size = note.size


			print(dn)
			print(note.profile)
			print(note.index)
			commandloader.saveSource(commandloader.sources[note.profile])
		end
	end
end)

local menus_renderer = imgui.OnFrame(function()
	return state.menus and #state.menus > 0
end, function(player)
	for mi, menu in ipairs(state.menus) do
		if menu.render[0] then
			imgui.SetNextWindowSize(imgui.ImVec2(menu.size.x*MDS, menu.size.y*MDS), imgui.Cond.FirstUseEver)
			local screenX, screenY = getScreenResolution()

			imgui.SetNextWindowPos(
				imgui.ImVec2(screenX / 2, screenY - 100),
				imgui.Cond.FirstUseEver,
				imgui.ImVec2(0.5, 0.5)
			)
			imgui.Begin(u8(menu.name .. "##" .. mi), menu.render)
			if not util.isEmpty(menu.description) then
				imutil.CenterText(u8(menu.description))
			end
			if menu.type == commandloader.menuTypes.CHOICE then
				for ci, choice in ipairs(menu.choices) do
					local isLast = ci == #menu.choices
					local isEven = ci % 2 == 0
					local middle = imutil.GetMiddleButtonX(isEven and 2 or (isLast and 1 or 2))
					if imgui.Button(u8(choice.name), imgui.ImVec2(middle, 30 * MDS)) then
						table.remove(state.menus, mi)
						menu.onChoice(choice)
					end

					if not isEven then
						imgui.SameLine()
					end
				end
			end
			imgui.End()
		end
	end
end)

local fastMenu = imgui.OnFrame(function()
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
		imgui.Begin(u8("�������� ��� ������� ") .. nickname, state.renderFastMenu)
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
								if
									imutil.ButtonWrappedTextCenter(
										("/%s\n%s"):format(u8(command.name), u8(command.description)),
										imgui.ImVec2(middleX, 40 * MDS)
									)
								then
									sampProcessChatInput("/" .. command.name .. " " .. state.fastMenuPlayerId)
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

local notifRenderer = imgui.OnFrame(function() return true end, function () 
	imutil.drawNotifications()
end)

function main()
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

	for _, source in pairs(commandloader.sources) do
		if source.enabled and #source.notes > 0 then
			for _, note in pairs(source.notes) do
				if note.openOnStart then
					table.insert(state.openedNotes, note)
				end
			end
		end
	end

	local env = util.merge(cfg.general, commandloader.env, {
		v = {}
	})
	while true do
		wait(0)
		for i, note in ipairs(state.openedNotes) do
			note.lastUpdate = note.lastUpdate or os.clock()
			if note.FPS > 0 and os.clock() - note.lastUpdate > 1 / note.FPS then
				note.lastUpdate = os.clock()
				local iter = note.text:gmatch("[^\r\n]+")

				local text = ""
				while true do
					local line = commandloader.processLine(iter, env)
					if line then
						text = text .. line .. "\n"
					elseif line == false then
						break
					end
				end

				note.formattedText = text
			end
		end
	end
end

require("samp.events").onShowDialog = function(dialogid, style, title, button1, button2, text)
	if dialogid == 235 and check_stats then
		if text:find("{FFFFFF}���: {B83434}%[(.-)]") then
			cfg.general.sex = text:match("{FFFFFF}���: {B83434}%[(.-)]")
		end
		if text:find("{FFFFFF}�����������: {B83434}%[(.-)]") then
			cfg.general.fraction = text:match("{FFFFFF}�����������: {B83434}%[(.-)]")
			state.fractionInput = imgui.new.char[256](u8(cfg.general.fraction))
		end
		if text:find("{FFFFFF}���������: {B83434}(.+)%((%d+)%)") then
			cfg.general.rank, cfg.general.rank_number =
				text:match("{FFFFFF}���������: {B83434}(.+)%((%d+)%)(.+)������� �������")
			state.rankInput = imgui.new.char[256](u8(cfg.general.rank))
			state.rankNumberInput = imgui.new.int(cfg.general.rank_number - 1)
		else
			sampAddChatMessage(
				"[MonetBinder] �� ������� ���������� ���� ���������.",
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
    imgui.GetStyle().Colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.70, 0.70, 0.70, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg] = imgui.ImVec4(0.05, 0.05, 0.05, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border] = imgui.ImVec4(0.25, 0.25, 0.26, 0.54)
    imgui.GetStyle().Colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    imgui.GetStyle().Colors[imgui.Col.CheckMark] = imgui.ImVec4(1.00, 1.00, 1.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.30, 0.30, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.25, 0.25, 0.26, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.40, 0.40, 0.40, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.20, 0.20, 0.20, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.47, 0.47, 0.47, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Separator] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive] = imgui.ImVec4(0.12, 0.12, 0.12, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip] = imgui.ImVec4(1.00, 1.00, 1.00, 0.25)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(1.00, 1.00, 1.00, 0.67)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(1.00, 1.00, 1.00, 0.95)
    imgui.GetStyle().Colors[imgui.Col.Tab] = imgui.ImVec4(0.15, 0.15, 0.15, 1.00)
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

function grayTheme()
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
    imgui.GetStyle().WindowRounding = 8
    imgui.GetStyle().ChildRounding = 8
    imgui.GetStyle().FrameRounding = 8
    imgui.GetStyle().PopupRounding = 8
    imgui.GetStyle().ScrollbarRounding = 8
    imgui.GetStyle().GrabRounding = 8
    imgui.GetStyle().TabRounding = 8

    --==[ ALIGN ]==--
    imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
    imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)

    --==[ COLORS ]==--
    imgui.GetStyle().Colors[imgui.Col.Text] = imgui.ImVec4(0.90, 0.90, 0.90, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextDisabled] = imgui.ImVec4(0.70, 0.70, 0.70, 1.00)
    imgui.GetStyle().Colors[imgui.Col.WindowBg] = imgui.ImVec4(0.15, 0.20, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ChildBg] = imgui.ImVec4(0.15, 0.20, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PopupBg] = imgui.ImVec4(0.15, 0.20, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Border] = imgui.ImVec4(5, 39, 29, 0.2) -- ����� ���� ��� ��������
    imgui.GetStyle().Colors[imgui.Col.BorderShadow] = imgui.ImVec4(0.00, 0.00, 0.00, 0.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBg] = imgui.ImVec4(0.20, 0.25, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgHovered] = imgui.ImVec4(0.25, 0.30, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.FrameBgActive] = imgui.ImVec4(0.30, 0.35, 0.40, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBg] = imgui.ImVec4(0.15, 0.20, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgActive] = imgui.ImVec4(0.20, 0.25, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TitleBgCollapsed] = imgui.ImVec4(0.15, 0.20, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.MenuBarBg] = imgui.ImVec4(0.15, 0.20, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarBg] = imgui.ImVec4(0.20, 0.25, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrab] = imgui.ImVec4(0.40, 0.45, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabHovered] = imgui.ImVec4(0.45, 0.50, 0.55, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ScrollbarGrabActive] = imgui.ImVec4(0.50, 0.55, 0.60, 1.00)
    imgui.GetStyle().Colors[imgui.Col.CheckMark] = imgui.ImVec4(0.90, 0.90, 0.90, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrab] = imgui.ImVec4(0.40, 0.45, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.SliderGrabActive] = imgui.ImVec4(0.50, 0.55, 0.60, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Button] = imgui.ImVec4(0.20, 0.25, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonHovered] = imgui.ImVec4(0.25, 0.30, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ButtonActive] = imgui.ImVec4(0.30, 0.35, 0.40, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Header] = imgui.ImVec4(0.20, 0.25, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderHovered] = imgui.ImVec4(0.25, 0.30, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.HeaderActive] = imgui.ImVec4(0.30, 0.35, 0.40, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Separator] = imgui.ImVec4(5, 39, 29, 0.2)
    imgui.GetStyle().Colors[imgui.Col.SeparatorHovered] = imgui.ImVec4(5, 39, 29, 0.2)
    imgui.GetStyle().Colors[imgui.Col.SeparatorActive] = imgui.ImVec4(5, 39, 29, 0.2)
    imgui.GetStyle().Colors[imgui.Col.ResizeGrip] = imgui.ImVec4(0.40, 0.45, 0.50, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripHovered] = imgui.ImVec4(0.45, 0.50, 0.55, 1.00)
    imgui.GetStyle().Colors[imgui.Col.ResizeGripActive] = imgui.ImVec4(0.50, 0.55, 0.60, 1.00)
    imgui.GetStyle().Colors[imgui.Col.Tab] = imgui.ImVec4(0.15, 0.20, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabHovered] = imgui.ImVec4(0.25, 0.30, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabActive] = imgui.ImVec4(0.30, 0.35, 0.40, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocused] = imgui.ImVec4(0.15, 0.20, 0.25, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TabUnfocusedActive] = imgui.ImVec4(0.20, 0.25, 0.30, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLines] = imgui.ImVec4(0.61, 0.61, 0.61, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotLinesHovered] = imgui.ImVec4(1.00, 0.43, 0.35, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogram] = imgui.ImVec4(0.90, 0.70, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.PlotHistogramHovered] = imgui.ImVec4(1.00, 0.60, 0.00, 1.00)
    imgui.GetStyle().Colors[imgui.Col.TextSelectedBg] = imgui.ImVec4(0.80, 0.95, 0.87, 0.35)
    imgui.GetStyle().Colors[imgui.Col.DragDropTarget] = imgui.ImVec4(0.80, 0.95, 0.87, 0.90)
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
