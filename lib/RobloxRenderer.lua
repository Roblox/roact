local Type = require(script.Parent.Type)
local ElementKind = require(script.Parent.ElementKind)
local Core = require(script.Parent.Core)

local RobloxRenderer = {}

function RobloxRenderer.mountHostNode(reconciler, node, element, hostParent, key)
	assert(Type.of(element) == Type.Element)
	assert(ElementKind.of(element) == ElementKind.Host)

	assert(element.props.Name == nil)
	assert(element.props.Parent == nil)

	local rbx = Instance.new(element.component)

	for name, value in pairs(element.props) do
		rbx[name] = value
	end

	rbx.Name = key

	local children = element.props[Core.Children]

	if children ~= nil then
		for childKey, childElement in pairs(children) do
			local childNode = reconciler.mountNode(childElement, rbx, childKey)

			node.children[childKey] = childNode
		end
	end

	rbx.Parent = hostParent
	node.hostObject = rbx
end

function RobloxRenderer.unmountHostNode(reconciler, node)
	for _, child in pairs(node.children) do
		reconciler.unmountNode(child)
	end

	node.hostObject:Destroy()
end

function RobloxRenderer.reconcileHostNode(reconciler, node, newElement)
	-- error("NYI")

	return node
end

return RobloxRenderer