local createReconciler = require(script.Parent.createReconciler)
local RobloxRenderer = require(script.Parent.RobloxRenderer)
local shallow = require(script.Parent.shallow)
local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local config = require(script.Parent.GlobalConfig).get()

local DEFAULT_RECONCILER = createReconciler(RobloxRenderer)

local InternalData = Symbol.named("InternalData")

local VirtualTree = {}
local VirtualTreePublic = {}
VirtualTreePublic.__index = VirtualTreePublic

function VirtualTree.mount(element, options)
	options = options or {}
	local hostParent = options.hostParent
	local hostKey = options.hostKey or "RoactTree"
	local reconciler = options.reconciler or DEFAULT_RECONCILER

	if config.typeChecks then
		assert(Type.of(element) == Type.Element, "Expected arg #1 to be of type Element")
		assert(reconciler.isHostObject(hostParent) or hostParent == nil, "Expected arg #2 to be a host object")
	end

	local rootNode = reconciler.mountVirtualNode(element, hostParent, hostKey)

	local tree = {
		[Type] = Type.VirtualTree,
		[InternalData] = {
			rootNode = rootNode,
			mounted = true,
			reconciler = reconciler,
		},
	}

	setmetatable(tree, VirtualTreePublic)

	return tree
end

function VirtualTree.update(tree, newElement)
	local internalData = tree[InternalData]

	if config.typeChecks then
		assert(Type.of(tree) == Type.VirtualTree, "Expected arg #1 to be a Roact handle")
		assert(Type.of(newElement) == Type.Element, "Expected arg #2 to be a Roact Element")
		assert(internalData.mounted, "Cannot updated a Roact tree that has been unmounted")
	end

	local reconciler = internalData.reconciler

	internalData.rootNode = reconciler.updateVirtualNode(internalData.rootNode, newElement)

	return tree
end

function VirtualTree.unmount(tree)
	local internalData = tree[InternalData]

	if config.typeChecks then
		assert(Type.of(tree) == Type.VirtualTree, "Expected arg #1 to be a Roact handle")
		assert(internalData.mounted, "Cannot unmounted a Roact tree that has already been unmounted")
	end

	internalData.mounted = false

	if internalData.rootNode ~= nil then
		local reconciler = internalData.reconciler

		reconciler.unmountVirtualNode(internalData.rootNode)
	end
end

function VirtualTreePublic:getShallowWrapper(options)
	assert(Type.of(self) == Type.VirtualTree, "Expected method getShallowWrapper to be called with `:`")

	local internalData = self[InternalData]
	local rootNode = internalData.rootNode

	return shallow(rootNode, options)
end

return VirtualTree