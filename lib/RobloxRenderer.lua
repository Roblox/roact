local ElementKind = require(script.Parent.ElementKind)
local Core = require(script.Parent.Core)

local function setHostProperty(node, key, newValue, oldValue)
	if newValue == oldValue then
		return
	end

	if key == Core.Children then
		return
	end

	local keyType = typeof(key)

	if keyType == "string" then
		node.hostObject[key] = newValue
	else
		-- TODO
		error("NYI")
	end
end

local RobloxRenderer = {}

function RobloxRenderer.mountHostNode(reconciler, node)
	local element = node.currentElement
	local hostParent = node.hostParent
	local key = node.key

	assert(ElementKind.of(element) == ElementKind.Host)

	assert(element.props.Name == nil)
	assert(element.props.Parent == nil)

	local instance = Instance.new(element.component)
	node.hostObject = instance

	for name, value in pairs(element.props) do
		setHostProperty(node, name, value, nil)
	end

	instance.Name = key

	local children = element.props[Core.Children]

	if children ~= nil then
		for childKey, childElement in pairs(children) do
			local childNode = reconciler.mountNode(childElement, instance, childKey)

			node.children[childKey] = childNode
		end
	end

	instance.Parent = hostParent
	node.hostObject = instance
end

function RobloxRenderer.unmountHostNode(reconciler, node)
	for _, child in pairs(node.children) do
		reconciler.unmountNode(child)
	end

	node.hostObject:Destroy()
end

function RobloxRenderer.reconcileHostNode(reconciler, node, newElement)
	local oldProps = node.currentElement.props
	local newProps = newElement.props

	-- Apply props that were added or updated
	for key, newValue in pairs(newProps) do
		local oldValue = oldProps[key]

		if newValue ~= oldValue then
			setHostProperty(node, key, newValue, oldValue)
		end
	end

	-- Apply props that were removed
	for key, oldValue in pairs(oldProps) do
		local newValue = newProps[key]

		if newValue == nil then
			setHostProperty(node, key, nil, oldValue)
		end
	end

	reconciler.reconcileNodeChildren(node, newElement.props[Core.Children])

	return node
end

return RobloxRenderer