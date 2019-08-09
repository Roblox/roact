--[[
	Packages up the internals of Roact and exposes a public API for it.
]]

local GlobalConfig = require(script.GlobalConfig)
local createReconcilerCompat = require(script.createReconcilerCompat)
local strict = require(script.strict)
local Binding = require(script.Binding)
local VirtualTree = require(script.VirtualTree)

local function mount(element, hostParent, hostKey)
	return VirtualTree.mount(element, {
		hostParent = hostParent,
		hostKey = hostKey,
	})
end

local reconcilerCompat = createReconcilerCompat(VirtualTree)

local Roact = strict {
	Component = require(script.Component),
	createElement = require(script.createElement),
	createFragment = require(script.createFragment),
	oneChild = require(script.oneChild),
	PureComponent = require(script.PureComponent),
	None = require(script.None),
	Portal = require(script.Portal),
	createRef = require(script.createRef),
	createBinding = Binding.create,
	joinBindings = Binding.join,

	Change = require(script.PropMarkers.Change),
	Children = require(script.PropMarkers.Children),
	Event = require(script.PropMarkers.Event),
	Ref = require(script.PropMarkers.Ref),

	mount = mount,
	unmount = VirtualTree.unmount,
	update = VirtualTree.update,

	reify = reconcilerCompat.reify,
	teardown = reconcilerCompat.teardown,
	reconcile = reconcilerCompat.reconcile,

	setGlobalConfig = GlobalConfig.set,

	-- APIs that may change in the future without warning
	UNSTABLE = {
	},
}

return Roact