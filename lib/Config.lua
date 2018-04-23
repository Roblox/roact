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

-- Every valid configuration value should be non-nil in this table.
local defaultConfig = {
	-- Enables storage of `debug.traceback()` values on elements for debugging.
	["elementTracing"] = false,
	-- Enables instrumentation of shouldUpdate and render methods for Roact components
	["componentInstrumentation"] = false,
}

-- Build a list of valid configuration values up for debug messages.
local defaultConfigKeys = {}
for key in pairs(defaultConfig) do
	table.insert(defaultConfigKeys, key)
end

--[[
	Merges two tables together into a new table.
]]
local function join(a, b)
	local new = {}

	for key, value in pairs(a) do
		new[key] = value
	end

	for key, value in pairs(b) do
		new[key] = value
	end

	return new
end

local Config = {}

function Config.new()
	local self = {}

	-- Once configuration has been set, we record a traceback.
	-- That way, if the user mistakenly calls `set` twice, we can point to the
	-- first place it was called.
	self._lastConfigTraceback = nil

	self._currentConfig = defaultConfig

	-- We manually bind these methods here so that the Config's methods can be
	-- used without passing in self, since they eventually get exposed on the
	-- root Roact object.
	self.set = function(...)
		return Config.set(self, ...)
	end

	self.getValue = function(...)
		return Config.getValue(self, ...)
	end

	self.reset = function(...)
		return Config.reset(self, ...)
	end

	return self
end

function Config.set(self, configValues)
	if self._lastConfigTraceback then
		local message = (
			"Global configuration can only be set once. Configuration was already set at:%s"
		):format(
			self._lastConfigTraceback
		)

		error(message, 3)
	end

	-- We use 3 as our traceback and error level because all of the methods are
	-- manually bound to 'self', which creates an additional stack frame we want
	-- to skip through.
	self._lastConfigTraceback = debug.traceback("", 3)

	-- Validate values without changing any configuration.
	-- We only want to apply this configuration if it's valid!
	for key, value in pairs(configValues) do
		if defaultConfig[key] == nil then
			local message = (
				"Invalid global configuration key %q (type %s). Valid configuration keys are: %s"
			):format(
				tostring(key),
				typeof(key),
				table.concat(defaultConfigKeys, ", ")
			)

			error(message, 3)
		end

		-- Right now, all configuration values must be boolean.
		if typeof(value) ~= "boolean" then
			local message = (
				"Invalid value %q (type %s) for global configuration key %q. Valid values are: true, false"
			):format(
				tostring(value),
				typeof(value),
				tostring(key)
			)

			error(message, 3)
		end
	end

	-- Assign all of the (validated) configuration values in one go.
	self._currentConfig = join(self._currentConfig, configValues)
end

function Config.getValue(self, key)
	if defaultConfig[key] == nil then
		local message = (
			"Invalid global configuration key %q (type %s). Valid configuration keys are: %s"
		):format(
			tostring(key),
			typeof(key),
			table.concat(defaultConfigKeys, ", ")
		)

		error(message, 3)
	end

	return self._currentConfig[key]
end

function Config.reset(self)
	self._lastConfigTraceback = nil
	self._currentConfig = defaultConfig
end

return Config