--[[
	Packages up the internals of Roact and exposes a public API for it.
]]

local Core = require(script.Core)
local GlobalConfig = require(script.GlobalConfig)
local createReconciler = require(script.createReconciler)
local createReconcilerCompat = require(script.createReconcilerCompat)
local RobloxRenderer = require(script.RobloxRenderer)
local strict = require(script.strict)

local robloxReconciler = createReconciler(RobloxRenderer)
local reconcilerCompat = createReconcilerCompat(robloxReconciler)

local Roact = strict {
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

	mount = robloxReconciler.mountTree,
	unmount = robloxReconciler.unmountTree,
	reconcile = robloxReconciler.reconcileTree,

	reify = reconcilerCompat.reify,
	teardown = reconcilerCompat.teardown,

	setGlobalConfig = GlobalConfig.set,
	getGlobalConfigValue = GlobalConfig.getValue,

	-- APIs that may change in the future without warning
	UNSTABLE = {
	},
}

return Roact