--[[
	Packages up the internals of Roact and exposes a public API for it.
]]

local Change = require(script.Change)
local Component = require(script.Component)
local Core = require(script.Core)
local createElement = require(script.createElement)
local createRef = require(script.createRef)
local Event = require(script.Event)
local GlobalConfig = require(script.GlobalConfig)
local Instrumentation = require(script.Instrumentation)
local oneChild = require(script.oneChild)
local PureComponent = require(script.PureComponent)
local Reconciler = require(script.Reconciler)
local ReconcilerCompat = require(script.ReconcilerCompat)

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
apply(Roact, ReconcilerCompat)

apply(Roact, {
	Change = Change,
	Component = Component,
	createElement = createElement,
	createRef = createRef,
	Event = Event,
	oneChild = oneChild,
	PureComponent = PureComponent,
})

apply(Roact, {
	setGlobalConfig = GlobalConfig.set,
	getGlobalConfigValue = GlobalConfig.getValue,
})

apply(Roact, {
	-- APIs that may change in the future
	UNSTABLE = {
		getCollectedStats = Instrumentation.getCollectedStats,
		clearCollectedStats = Instrumentation.clearCollectedStats,
	}
})

return Roact