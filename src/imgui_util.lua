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

function imutil.Setting(name, setting, callback, close_button)
	close_button = close_button == nil and true or close_button
	imgui.BeginChild(name, imgui.ImVec2(0, 40 * MDS), true)
	imgui.Text(setting)
	imgui.SameLine()

	local size = imgui.ImVec2(30 * MDS, 30 * MDS)
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
		callback()
		if close_button then
			imgui.Dummy(imgui.ImVec2(0, 30 * MDS))
			imgui.SetCursorPosY(
				imgui.GetWindowHeight() - imgui.GetStyle().FramePadding.y - 30 * MDS + imgui.GetScrollY()
			)
			if
				imutil.CenterButton(
					fa.XMARK .. u8(" Закрыть"),
					imgui.ImVec2(imgui.GetWindowWidth() * 0.85, 30 * MDS)
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
	imgui.BeginChild(setting, imgui.ImVec2(0, 40 * MDS), true)
	imgui.Text(setting)
	imgui.SameLine()

	local size = imgui.ImVec2(30 * MDS, 30 * MDS)
	imgui.SetCursorPosX(imutil.GetEndPosButtonX(size, 1))
	local button = imgui.Button(fa.PEN, size)
	imgui.EndChild()
	return button
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

function imutil.CenterText(text)
	local width = imgui.GetWindowWidth()
	local calc = imgui.CalcTextSize(text)
	imgui.SetCursorPosX(width / 2 - calc.x / 2)
	imgui.Text(text)
end

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
