local Type = require(script.Parent.Type)
local ElementKind = require(script.Parent.ElementKind)
local Core = require(script.Parent.Core)

local RobloxRenderer = {}

function RobloxRenderer.mountHostNode(node, element, hostParent, key, mountNode)
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
			local childNode = mountNode(childElement, rbx, childKey)

			node.children[childKey] = childNode
		end
	end

	rbx.Parent = hostParent
	node.hostObject = rbx
end

function RobloxRenderer.unmountHostNode(node, unmountNode)
	for _, child in pairs(node.children) do
		unmountNode(child)
	end

	node.hostObject:Destroy()
end

function RobloxRenderer.reconcileHostNode(node, newElement)
	error("NYI")
end

return RobloxRenderer