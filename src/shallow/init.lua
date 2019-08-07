local createReconciler = require(script.Parent.createReconciler)
local Type = require(script.Parent.Type)
local RobloxRenderer = require(script.Parent.RobloxRenderer)
local ShallowWrapper = require(script.ShallowWrapper)

local robloxReconciler = createReconciler(RobloxRenderer)

local shallowTreeKey = "RoactTree"

local function shallow(element, options)
	assert(Type.of(element) == Type.Element, "Expected arg #1 to be an Element")

	options = options or {}
	local maxDepth = options.depth or 1

	local rootNode = robloxReconciler.mountVirtualNode(element, nil, shallowTreeKey)

	return ShallowWrapper.new(rootNode, maxDepth)
end

return shallow