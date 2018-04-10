--[[
	Packages up the internals of Roact and exposes a public API for it.
]]

local Component = require(script.Component)
local Core = require(script.Core)
local Event = require(script.Event)
local Change = require(script.Change)
local GlobalConfig = require(script.GlobalConfig)
local Instrumentation = require(script.Instrumentation)
local PureComponent = require(script.PureComponent)
local Reconciler = require(script.Reconciler)

--[[
	A utility to copy one module into another, erroring if there are
	overlapping keys.

	Any keys that begin with an underscore are considered private.
]]
local function apply(target, source)
	for key, value in pairs(source) do
		if target[key] ~= nil then
			error(("Roact: key %q was overridden!"):format(key), 2)
		end

		-- Don't add internal values
		if not key:find("^_") then
			target[key] = value
		end
	end
end

local Roact = {}

apply(Roact, Core)
apply(Roact, Reconciler)

apply(Roact, {
	Component = Component,
	PureComponent = PureComponent,
	Event = Event,
	Change = Change,
	Instrumentation = Instrumentation,
})

apply(Roact, {
	setGlobalConfig = GlobalConfig.set,
	getGlobalConfigValue = GlobalConfig.getValue,
})

return Roact