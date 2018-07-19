--[[
	Packages up the internals of Roact and exposes a public API for it.
]]

local Core = require(script.Core)
local GlobalConfig = require(script.GlobalConfig)
local Instrumentation = require(script.Instrumentation)
local Reconciler = require(script.Reconciler)
local ReconcilerCompat = require(script.ReconcilerCompat)

local Roact = {
	Change = require(script.Change),
	Component = require(script.Component),
	createElement = require(script.createElement),
	createRef = require(script.createRef),
	Event = require(script.Event),
	oneChild = require(script.oneChild),
	PureComponent = require(script.PureComponent),

	Children = Core.Children,
	Element = Core.Element,
	None = Core.None,
	Portal = Core.Portal,
	Ref = Core.Ref,

	mount = Reconciler.mount,
	unmount = Reconciler.unmount,
	reconcile = Reconciler.reconcile,

	reify = ReconcilerCompat.reify,
	teardown = ReconcilerCompat.teardown,

	setGlobalConfig = GlobalConfig.set,
	getGlobalConfigValue = GlobalConfig.getValue,

	-- APIs that may change in the future without warning
	UNSTABLE = {
		getCollectedStats = Instrumentation.getCollectedStats,
		clearCollectedStats = Instrumentation.clearCollectedStats,
	},
}

return Roact