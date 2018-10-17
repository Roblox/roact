--[[
	Renderer that deals in terms of Roblox Instances. This is the most
	well-supported renderer after NoopRenderer and is currently the only
	renderer that does anything.
]]

local ElementKind = require(script.Parent.ElementKind)
local Binding = require(script.Parent.Binding)
local Ref = require(script.Parent.Ref)
local Type = require(script.Parent.Type)
local getDefaultPropertyValue = require(script.Parent.getDefaultPropertyValue)
local Children = require(script.Parent.PropMarkers.Children)

local RefMarker = require(script.Parent.PropMarkers.Ref)

local function bindHostProperty(node, key, newBinding)
	local function updateBoundProperty(newValue)
		node.hostObject[key] = newValue
	end

	if node.bindings == nil then
		node.bindings = {}
	end

	node.bindings[key] = Binding.subscribe(newBinding, updateBoundProperty)

	return newBinding.getValue()
end

local function setHostProperty(node, key, newValue, oldValue)
	if newValue == oldValue then
		return
	end

	if key == Children then
		return
	end

	local keyType = typeof(key)

	if keyType == "string" then
		if newValue == nil then
			local hostClass = node.hostObject.ClassName
			local _, defaultValue = getDefaultPropertyValue(hostClass, key)
			newValue = defaultValue
		end

		-- If either value is a Ref, unwrap it into a Binding
		if Type.of(newValue) == Type.Ref then
			newValue = Ref.getBinding(newValue)
		end

		if Type.of(oldValue) == Type.Ref then
			oldValue = Ref.getBinding(oldValue)
		end

		-- If either value is a Binding, detach or attach it as expected
		if Type.of(oldValue) == Type.Binding then
			local disconnect = node.bindings[key]

			node.bindings[key] = disconnect()
		end

		if Type.of(newValue) == Type.Binding then
			newValue = bindHostProperty(node, key, newValue)
		end

		-- Assign the new value to the object
		node.hostObject[key] = newValue
	elseif key == RefMarker then
		Ref.apply(oldValue, nil)
		Ref.apply(newValue, node.hostObject)
	else
		-- TODO
		error(("%s: NYI"):format(tostring(key)))
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

	local children = element.props[Children]

	if children ~= nil then
		for childKey, childElement in pairs(children) do
			local childNode = reconciler.mountVirtualNode(childElement, instance, childKey)

			node.children[childKey] = childNode
		end
	end

	instance.Parent = hostParent
	node.hostObject = instance
end

function RobloxRenderer.unmountHostNode(reconciler, node)
	for _, childNode in pairs(node.children) do
		reconciler.unmountVirtualNode(childNode)
	end

	if node.bindings ~= nil then
		for _, disconnect in pairs(node.bindings) do
			disconnect()
		end
	end

	node.hostObject:Destroy()
end

function RobloxRenderer.updateHostNode(reconciler, node, newElement)
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

	reconciler.updateVirtualNodeChildren(node, newElement.props[Children])

	return node
end

return RobloxRenderer