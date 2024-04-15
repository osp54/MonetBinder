local c = config
local version = "1.3.2"

local fmt = string.format

c:set_main("src/MonetBinder.lua")
c:set_encoding("cp1251")
c:set_output(fmt("dist/MonetBinder_v%s.lua", version))

c:add_module("src/*[!MonetBinder]*.lua")
c:add_module("lib/*[!inspect]*[!android]*.lua")

function remove_indentation(code)
    local output = ""
    local min_indent = math.huge

    -- Find the minimum indentation level
    for line in code:gmatch("[^\r\n]+") do
        local indent = #(line:match("^%s*"))
        if indent < min_indent then
            min_indent = indent
        end
    end

    -- Remove the indentation
    for line in code:gmatch("[^\r\n]+") do
        local indent = #(line:match("^%s*"))
        output = output .. line:sub(indent - min_indent + 1) .. "\n"
    end

    return output
end

function postprocess(content)
    local output = ""

    for line in content:gmatch("[^\r\n]+") do
        if not line:find("^%-%-%-") then
            output = output .. line .. "\n"
        end
    end

    return remove_indentation(output):gsub("%%VERSION%%", version)
end