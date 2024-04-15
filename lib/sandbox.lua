local sandbox = {
}
local quota_supported = type(_G.jit) == "nil"
sandbox.quota_supported = quota_supported
local bytecode_blocked = _ENV or type(_G.jit) == "table"
sandbox.bytecode_blocked = bytecode_blocked
local BASE_ENV = {};
([[
  
  _VERSION assert error    ipairs   next pairs
  pcall    select tonumber tostring type unpack xpcall
  
  coroutine.create coroutine.resume coroutine.running coroutine.status
  coroutine.wrap   coroutine.yield
  
  math.abs   math.acos math.asin  math.atan math.atan2 math.ceil
  math.cos   math.cosh math.deg   math.exp  math.fmod  math.floor
  math.frexp math.huge math.ldexp math.log  math.log10 math.max
  math.min   math.modf math.pi    math.pow  math.rad   math.random
  math.sin   math.sinh math.sqrt  math.tan  math.tanh
  
  os.clock os.difftime os.time
  
  string.byte string.char  string.find  string.format string.gmatch
  string.gsub string.len   string.lower string.match  string.reverse
  string.sub  string.upper
  
  table.insert table.maxn table.remove table.sort
  
  ]]):gsub("%S+", function(id)
	local module, method = id:match("([^%.]+)%.([^%.]+)")
	if module then
		BASE_ENV[module] = BASE_ENV[module] or {}
		BASE_ENV[module][method] = _G[module][method]
	else
		BASE_ENV[id] = _G[id]
	end
end)

local function protect_module(module, module_name)
	return setmetatable({}, {
		__index = module,
		__newindex = function(_, attr_name, _)
			error("Can not modify " .. module_name .. "." .. attr_name .. ". Protected by the sandbox.")
		end,
	})
end

("coroutine math os string table"):gsub("%S+", function(module_name)
	BASE_ENV[module_name] = protect_module(BASE_ENV[module_name], module_name)
end)

local string_rep = string.rep

local function sethook(f, key, quota)
	if type(debug) ~= "table" or type(debug.sethook) ~= "function" then
		return
	end
	debug.sethook(f, key, quota)
end

local function cleanup()
	sethook()
	string.rep = string_rep -- luacheck: no global
end

table.pack = table.pack or function(...)
    return {n = select("#", ...), ...}
end
table.unpack = table.unpack or unpack
function sandbox.protect(code, options)
	options = options or {}

	local quota = false
	if options.quota and not quota_supported then
		error("options.quota is not supported on this environment (usually LuaJIT). Please unset options.quota")
	end
	if options.quota ~= false then
		quota = options.quota or 500000
	end

	assert(type(code) == "string", "expected a string")

	local passed_env = options.env or {}
	local env = {}
	for k, v in pairs(BASE_ENV) do
		local pv = passed_env[k]
		if pv ~= nil then
			env[k] = pv
		else
			env[k] = v
		end
	end
	setmetatable(env, {
		__index = options.env,
	})
	env._G = env

	local f
	if bytecode_blocked then
		f = assert(load(code, nil, "t", env))
	else
		f = assert(loadstring(code))
		setfenv(f, env)
	end

	return function(...)
		if quota and quota_supported then
			local timeout = function()
				cleanup()
				error("Quota exceeded: " .. tostring(quota))
			end
			sethook(timeout, "", quota)
		end

		string.rep = nil -- luacheck: no global

		local t = table.pack(pcall(f, ...))

		cleanup()

		if not t[1] then
			error(t[2])
		end

		return table.unpack(t, 2, t.n)
	end
end

function sandbox.run(code, options, ...)
	return sandbox.protect(code, options)(...)
end

setmetatable(sandbox, {
	__call = function(_, code, o)
		return sandbox.protect(code, o)
	end,
})

return sandbox
