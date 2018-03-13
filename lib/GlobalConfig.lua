--[[
	Exposes an interface to set global configuration values for Roact.

	Configuration can only occur once, and should only be done by an application
	using Roact, not a library.

	Any keys that aren't recognized will cause errors. Configuration is only
	intended for configuring Roact itself, not extensions or libraries.

	Configuration is expected to be set immediately after loading Roact. Setting
	configuration values after an application starts may produce unpredictable
	behavior.
]]

local validConfigKeyList = {
	-- Enables storage of `debug.traceback()` values on elements for debugging.
	"elementTracing",
}

-- Transform our list of keys into a set for fast lookups.
local validConfigKeys = {}
for _, name in ipairs(validConfigKeyList) do
	validConfigKeys[name] = true
end

local GlobalConfig = {}

-- Once configuration has been set, we record a traceback.
-- That way, if the user mistakenly calls `set` twice, we can point to the
-- first place it was called.
GlobalConfig._lastConfigTraceback = nil

GlobalConfig._currentConfig = {
	["elementTracing"] = false,
}

function GlobalConfig.set(configValues)
	if GlobalConfig._lastConfigTraceback then
		local message = (
			"Global configuration can only be set once. Configuration was already set at:%s"
		):format(
			GlobalConfig._lastConfigTraceback
		)

		error(message, 2)
	end

	GlobalConfig._lastConfigTraceback = debug.traceback("", 2)

	for key, value in pairs(configValues) do
		if not validConfigKeys[key] then
			local message = (
				"Invalid global configuration key %q (type %s). Valid configuration keys are: %s"
			):format(
				tostring(key),
				typeof(key),
				table.concat(validConfigKeyList, ", ")
			)

			error(message, 2)
		end

		-- Right now, all configuration values must be boolean.
		if typeof(value) ~= "boolean" then
			local message = (
				"Invalid value for global configuration key %q (type %s). Valid values are: true, false"
			):format(
				tostring(key),
				typeof(key)
			)

			error(message, 2)
		end

		GlobalConfig._currentConfig[key] = value
	end
end

function GlobalConfig.getValue(key)
	if not validConfigKeys[key] then
		local message = (
			"Invalid global configuration key %q (type %s). Valid configuration keys are: %s"
		):format(
			tostring(key),
			typeof(key),
			table.concat(validConfigKeyList, ", ")
		)

		error(message, 2)
	end

	return GlobalConfig._currentConfig[key]
end

return GlobalConfig