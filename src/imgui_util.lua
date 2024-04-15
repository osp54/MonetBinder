local imutil = {}

function imutil.shortifyText(text, parentWidth)
	local width = parentWidth or imgui.GetWindowContentRegionWidth()
	local calc = imgui.CalcTextSize(text)
	if calc.x > width then
		local len = math.floor(text:len() * (width / calc.x))
		return text:sub(1, len - 3) .. "..."
	end
	return text
end

local notifications = {}

function imutil.addNotification(text, duration)
    table.insert(notifications, {
        text = text,
        duration = duration,
        alpha = 0, -- начальная прозрачность
        state = "appearing" -- начальное состояние
    })
end

function imutil.drawNotifications()
    local ImGui = imgui
    local draw_list = ImGui.GetBackgroundDrawList()
    local screen_width, screen_height = getScreenResolution()
    local notification_height = 30
    local notification_margin = 10
    local animation_speed = 0.02

    for i, notification in ipairs(notifications) do
        if notification.state == "appearing" then
            notification.alpha = notification.alpha + animation_speed
            if notification.alpha >= 1 then
                notification.alpha = 1
                notification.state = "displaying"
                notification.display_start = os.clock()
            end
        elseif notification.state == "displaying" then
            if os.clock() - notification.display_start >= notification.duration then
                notification.state = "disappearing"
            end
        elseif notification.state == "disappearing" then
            notification.alpha = notification.alpha - animation_speed
            if notification.alpha <= 0 then
                table.remove(notifications, i)
            end
        end

        local text_size = ImGui.CalcTextSize(notification.text)
        local notification_width = text_size.x + 20
        local x = (screen_width - notification_width) / 2
        local y = screen_height - (notification_height + notification_margin) * i

        draw_list:AddRectFilled(ImGui.ImVec2(x, y), ImGui.ImVec2(x + notification_width, y + notification_height), ImGui.ColorConvertFloat4ToU32(ImGui.ImVec4(0.1, 0.1, 0.1, notification.alpha)), 5)
        draw_list:AddText(ImGui.ImVec2(x + 10, y + (notification_height - text_size.y) / 2), ImGui.ColorConvertFloat4ToU32(ImGui.ImVec4(1, 1, 1, notification.alpha)), notification.text)
    end
end

function imutil.ItemSelector(name, items, selected, fixedSize, dontDrawBorders)
    assert(items and #items > 1, 'items must be array of strings');
    assert(selected[0], 'Wrong argument #3. Selected must be "imgui.new.int"');
    local DL = imgui.GetWindowDrawList();
    local style = {
        rounding = imgui.GetStyle().FrameRounding,
        padding = imgui.GetStyle().FramePadding,
        col = {
            default = imgui.GetStyle().Colors[imgui.Col.Button],
            hovered = imgui.GetStyle().Colors[imgui.Col.ButtonHovered],
            active = imgui.GetStyle().Colors[imgui.Col.ButtonActive],
            text = imgui.GetStyle().Colors[imgui.Col.Text]
        }
    };
    local pos = imgui.GetCursorScreenPos();
    local start = pos;
    local maxSize = 0;
    for index, item in ipairs(items) do
        local textSize = imgui.CalcTextSize(item);
        local sizeX = (fixedSize or textSize.x) + style.padding.x * 2;
        imgui.SetCursorScreenPos(pos);
        if imgui.InvisibleButton('##imguiSelector_'..item..'_'..tostring(index), imgui.ImVec2(sizeX, textSize.y + style.padding.y * 2)) then
            local old = selected[0];
            selected[0] = index;
            return selected[0], old;
        end
        DL:AddRectFilled(
            pos,
            imgui.ImVec2(pos.x + sizeX, pos.y + textSize.y + style.padding.y * 2),
            imgui.GetColorU32Vec4((selected[0] == index or imgui.IsItemActive()) and style.col.active or (imgui.IsItemHovered() and style.col.hovered or style.col.default)),
            style.rounding,
            (index == 1 and 5 or (index == #items and 10 or 0))
        );
        if index > 1 and not dontDrawBorders then DL:AddLine(imgui.ImVec2(pos.x, pos.y + style.padding.y), imgui.ImVec2(pos.x, pos.y + textSize.y + style.padding.y), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Border]), 1) end
        DL:AddText(imgui.ImVec2(pos.x + sizeX / 2 - textSize.x / 2, pos.y + style.padding.y), imgui.GetColorU32Vec4(style.col.text), item);
        pos = imgui.ImVec2(pos.x + sizeX, pos.y);
    end
    DL:AddRect(start, imgui.ImVec2(pos.x, pos.y + imgui.CalcTextSize('A').y + style.padding.y * 2), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Border]), imgui.GetStyle().FrameRounding, nil, imgui.GetStyle().FrameBorderSize);
    DL:AddText(imgui.ImVec2(pos.x + style.padding.x, pos.y + (imgui.CalcTextSize(name).y + style.padding.y * 2) / 2 - imgui.CalcTextSize(name).y / 2), imgui.GetColorU32Vec4(style.col.text), name);
end

function imutil.GetMiddleColumnX(count)
	local window_width = imgui.GetWindowWidth()
	local total_spacing = imgui.GetStyle().ItemSpacing.x * (count - 1)
	local total_columns_width = window_width - (total_spacing + imgui.GetStyle().FramePadding.x * 2 * count)
	return total_columns_width / (3 * count)
end

function imutil.GetMiddleButtonX(count)
	local width = imgui.GetWindowContentRegionWidth()
	local space = imgui.GetStyle().ItemSpacing.x
	return count == 1 and width or width / count - ((space * (count - 1)) / count)
end

function imutil.ToggleButton(str_id, bool)
    local rBool = false

    if LastActiveTime == nil then
        LastActiveTime = {}
    end
    if LastActive == nil then
        LastActive = {}
    end

    local function ImSaturate(f)
        return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
    end

    local p = imgui.GetCursorScreenPos()
    local dl = imgui.GetWindowDrawList()

    local height = imgui.GetTextLineHeightWithSpacing()
    local width = height * 1.70
    local radius = height * 0.50
    local ANIM_SPEED = type == 2 and 0.10 or 0.15
    local butPos = imgui.GetCursorPos()

    if imgui.InvisibleButton(str_id, imgui.ImVec2(width, height)) then
        bool[0] = not bool[0]
        rBool = true
        LastActiveTime[tostring(str_id)] = os.clock()
        LastActive[tostring(str_id)] = true
    end

    imgui.SetCursorPos(imgui.ImVec2(butPos.x + width + 8, butPos.y + 2.5))
    imgui.Text( str_id:gsub('##.+', '') )

    local t = bool[0] and 1.0 or 0.0

    if LastActive[tostring(str_id)] then
        local time = os.clock() - LastActiveTime[tostring(str_id)]
        if time <= ANIM_SPEED then
            local t_anim = ImSaturate(time / ANIM_SPEED)
            t = bool[0] and t_anim or 1.0 - t_anim
        else
            LastActive[tostring(str_id)] = false
        end
    end

    local col_circle = bool[0] and imgui.ColorConvertFloat4ToU32(imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.ButtonActive])) or imgui.ColorConvertFloat4ToU32(imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.TextDisabled]))
    dl:AddRectFilled(p, imgui.ImVec2(p.x + width, p.y + height), imgui.ColorConvertFloat4ToU32(imgui.GetStyle().Colors[imgui.Col.FrameBg]), height * 0.5)
    dl:AddCircleFilled(imgui.ImVec2(p.x + radius + t * (width - radius * 2.0), p.y + radius), radius - 1.5, col_circle)
    return rBool
end

function imutil.ToggleButtonIcon(icon_on, icon_off, state, size)
	size = size or imgui.ImVec2(30 * MDS, 30 * MDS)
	if state then
		return imgui.Button(icon_on, size)
	else
		return imgui.Button(icon_off, size)
	end
end

function imutil.GetEndPosButtonX(size, count)
	local width = imgui.GetWindowWidth()
	local space = imgui.GetStyle().FramePadding.x
	return width - (size.x * count) - (space * count)
end

function imutil.ConfirmationPopup(name, text)
	if imgui.BeginPopupModal(name, _, imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove) then
		imgui.SetWindowSizeVec2(imgui.ImVec2(300 * MDS, 150 * MDS))
		imgui.SetCursorPosY(imgui.GetWindowHeight() / 2 - 30 * MDS)
		imutil.CenterText(text)
		imgui.SetCursorPosY(imgui.GetWindowHeight() - imgui.GetStyle().FramePadding.y - 30 * MDS)
		if imgui.Button(fa.CHECK .. u8(" Да"), imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
			imgui.CloseCurrentPopup()
			imgui.EndPopup()
			return true
		end
		imgui.SameLine()
		if imgui.Button(fa.XMARK .. u8(" Нет"), imgui.ImVec2(imutil.GetMiddleButtonX(2), 30 * MDS)) then
			imgui.CloseCurrentPopup()
			imgui.EndPopup()
			return false
		end

		imgui.EndPopup()
	end
	return false

end

function imutil.Setting(name, setting, callback, close_button)
	close_button = close_button == nil and true or close_button
	imgui.BeginChild(name, imgui.ImVec2(0, 35 * MDS), true)
	imgui.Text(setting)
	imgui.SameLine()

	local size = imgui.ImVec2(25 * MDS, 25 * MDS)
	imgui.SetCursorPosX(imutil.GetEndPosButtonX(size, 1))
	if imgui.Button(fa.PEN, size) then
		imgui.OpenPopup(name)
	end

	if
		imgui.BeginPopupModal(
			name,
			_,
			imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoMove
		)
	then
		imgui.SetWindowSizeVec2(imgui.ImVec2(400 * MDS, 200 * MDS))
		if close_button then
			imgui.BeginChild("##setting"..name, imgui.ImVec2(0, imgui.GetWindowSize().y - 30 * MDS - imgui.GetCursorPosY() - imgui.GetStyle().FramePadding.y * 2), true)
		end
		callback()
		if close_button then
			imgui.EndChild()
		end
		if close_button then
			if
				imgui.Button(
					fa.XMARK .. u8(" Закрыть"),
					imgui.ImVec2(imutil.GetMiddleButtonX(1), 30 * MDS)
				)
			then
				imgui.CloseCurrentPopup()
			end
		end
		imgui.EndPopup()
	end

	imgui.EndChild()
end

function imutil.SettingButton(setting)
	imgui.BeginChild(setting, imgui.ImVec2(0, 35 * MDS), true)
	imgui.Text(setting)
	imgui.SameLine()

	local size = imgui.ImVec2(25 * MDS, 25 * MDS)
	imgui.SetCursorPosX(imutil.GetEndPosButtonX(size, 1))
	local button = imgui.Button(fa.PEN, size)
	imgui.EndChild()
	return button
end

function imutil.CenterColumnText(text)
    imgui.SetCursorPosX((imgui.GetColumnOffset() + (imgui.GetColumnWidth() / 2)) - imgui.CalcTextSize(text).x / 2)
    imgui.Text(text)
end

function imutil.CenterButton(label, bsize, alignment)
	bsize = bsize or imgui.ImVec2(0, 0)
	alignment = alignment or 0.5
	local style = imgui.GetStyle()

	local size = bsize.x + style.FramePadding.x * 2.0
	local avail = imgui.GetContentRegionAvail().x

	local off = (avail - size) * alignment
	if off > 0.0 then
		imgui.SetCursorPosX(imgui.GetCursorPosX() + off)
	end

	return imgui.Button(label, bsize)
end

function imutil.CenterError(text)
	local width = imgui.GetWindowWidth()
	local calc = imgui.CalcTextSize(text)
	imgui.Text(fa.BUG .. u8(" "))
	imgui.SameLine()
	imgui.SetCursorPosX(width / 2 - calc.x / 2)
	imgui.TextColored(imgui.ImVec4(1, 0, 0, 1), text)
end

function imutil.CenterText(text, parentWidth)
	local width = parentWidth or imgui.GetWindowWidth()
	local calc = imgui.CalcTextSize(text)
	imgui.SetCursorPosX(width / 2 - calc.x / 2)
	imgui.Text(text)
end

--- Draw a button with text that wraps to fit the button width and is centered.
---@param text string
---@param size ImVec2
---@return boolean
function imutil.ButtonWrappedTextCenter(text, size)
    local is_pressed = imgui.Button("##"..text, size)
    local button_min, button_max = imgui.GetItemRectMin(), imgui.GetItemRectMax()
    
    local lines = {}
    for line in text:gmatch("[^\n]+") do
        table.insert(lines, line)
    end
    
    -- Get draw list and add text for each line
    local draw_list = imgui.GetWindowDrawList()
    local text_size = imgui.CalcTextSize(text)
    local line_height = text_size.y / #lines
    local text_y = button_min.y + (button_max.y - button_min.y - text_size.y) / 2
    
    for i, line in ipairs(lines) do
        local text_size_line = imgui.CalcTextSize(line)
        local text_x = button_min.x + (button_max.x - button_min.x - text_size_line.x) / 2
        local text_pos = imgui.ImVec2(text_x, text_y + (i - 1) * line_height)
        draw_list:AddText(text_pos, imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col.Text]), line)
    end
    
    return is_pressed
end

function imutil.BackgroundButton(label, open, pos, size, color, movable)
	if not pos then
		error("pos is nil")
	end
	size = size or imgui.ImVec2(0, 0)
	color = color or imgui.ImVec4(0.0, 0.0, 1.0, 0.5) -- deepskyblue

	local cond = movable and imgui.Cond.Once or imgui.Cond.Always
	imgui.SetNextWindowPos(pos, cond)
	imgui.SetNextWindowSize(size, cond)
	if movable then
		imgui.Begin("##bg", open)
	else
		imgui.Begin(
			"##bg",
			open,
			imgui.WindowFlags.NoTitleBar
				+ imgui.WindowFlags.NoResize
				+ imgui.WindowFlags.NoMove
				+ imgui.WindowFlags.NoBackground
		)
	end
	imgui.PushStyleColor(imgui.Col.Button, color)
	local button = imgui.Button(label, imgui.GetContentRegionAvail())

	local pos, size = imgui.GetWindowPos(), imgui.GetWindowSize()
	imgui.PopStyleColor()
	imgui.End()

	return button, pos, size
end

return imutil
