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
	-- Enables asserts for internal Roact APIs. Useful for debugging Roact itself.
	["devAsserts"] = false,
	-- Enables stricter type asserts for Roact's public API.
	["strictMode"] = false,
	-- Enables storage of `debug.traceback()` values on elements for debugging.
	["elementTracing"] = false,
	-- Enables validation of component props in stateful components.
	["propertyValidation"] = false,
}

-- Build a list of valid configuration values up for debug messages.
local defaultConfigKeys = {}
for key in pairs(defaultConfig) do
	table.insert(defaultConfigKeys, key)
end

local Config = {}

function Config.new()
	local self = {}

	self._currentConfig = setmetatable({}, {
		__index = function(_, key)
			local message = (
				"Invalid global configuration key %q. Valid configuration keys are: %s"
			):format(
				tostring(key),
				table.concat(defaultConfigKeys, ", ")
			)

			error(message, 3)
		end
	})

	-- We manually bind these methods here so that the Config's methods can be
	-- used without passing in self, since they eventually get exposed on the
	-- root Roact object.
	self.set = function(...)
		return Config.set(self, ...)
	end

	self.get = function(...)
		return Config.get(self, ...)
	end

	self.reset = function(...)
		return Config.reset(self, ...)
	end

	self.scoped = function(...)
		return Config.scoped(self, ...)
	end

	self.set(defaultConfig)

	-- Once configuration has been set, we record a traceback.
	-- That way, if the user mistakenly calls `set` twice, we can point to the
	-- first place it was called.
	self._lastConfigTraceback = nil

	return self
end

function Config:set(configValues)
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

	-- Once validated, we mutate our config table so that all consumers who
	-- stored the result of get have the correct values
	for key, value in pairs(configValues) do
		self._currentConfig[key] = value
	end
end

function Config:get()
	return self._currentConfig
end

function Config:reset()
	self._lastConfigTraceback = nil
	for key, value in pairs(defaultConfig) do
		self._currentConfig[key] = value
	end
end

function Config:scoped(configValues, callback)
	self.set(configValues)

	local success, result = pcall(callback)

	self.reset()

	assert(success, result)
end

return Config