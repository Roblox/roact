--[[
	Renderer that deals in terms of Roblox Instances. This is the most
	well-supported renderer after NoopRenderer and is currently the only
	renderer that does anything.
]]

local Binding = require(script.Parent.Binding)
local Children = require(script.Parent.PropMarkers.Children)
local ElementKind = require(script.Parent.ElementKind)
local SingleEventManager = require(script.Parent.SingleEventManager)
local getDefaultInstanceProperty = require(script.Parent.getDefaultInstanceProperty)
local Ref = require(script.Parent.PropMarkers.Ref)
local Type = require(script.Parent.Type)

local function applyRef(ref, newHostObject)
	if ref == nil then
		return
	end

	if typeof(ref) == "function" then
		ref(newHostObject)
	elseif Type.of(ref) == Type.Binding then
		Binding.update(ref, newHostObject)
	else
		-- TODO: Better error message
		error(("Invalid ref: Expected type Binding but got %s"):format(
			typeof(ref)
		))
	end
end

local function setRobloxInstanceProperty(hostObject, key, newValue)
	if newValue == nil then
		local hostClass = hostObject.ClassName
		local _, defaultValue = getDefaultInstanceProperty(hostClass, key)
		newValue = defaultValue
	end

	-- Assign the new value to the object
	-- TODO: Handle errors if `key` is not a valid Instance property
	hostObject[key] = newValue

	return
end

local function removeBinding(virtualNode, key)
	local disconnect = virtualNode.bindings[key]
	disconnect()
	virtualNode.bindings[key] = nil
end

local function attachBinding(virtualNode, key, newBinding)
	local function updateBoundProperty(newValue)
		setRobloxInstanceProperty(virtualNode.hostObject, key, newValue)
	end

	if virtualNode.bindings == nil then
		virtualNode.bindings = {}
	end

	virtualNode.bindings[key] = Binding.subscribe(newBinding, updateBoundProperty)

	setRobloxInstanceProperty(virtualNode.hostObject, key, newBinding:getValue())
end

local function detachAllBindings(virtualNode)
	if virtualNode.bindings ~= nil then
		for _, disconnect in pairs(virtualNode.bindings) do
			disconnect()
		end
	end
end

local function applyProp(virtualNode, key, newValue, oldValue)
	if newValue == oldValue then
		return
	end

	if key == Ref or key == Children then
		-- Refs and children are handled in a separate pass
		return
	end

	local internalKeyType = Type.of(key)

	if internalKeyType == Type.HostEvent or internalKeyType == Type.HostChangeEvent then
		if virtualNode.eventManager == nil then
			virtualNode.eventManager = SingleEventManager.new(virtualNode.hostObject)
		end

		local eventName = key.name

		if internalKeyType == Type.HostChangeEvent then
			virtualNode.eventManager:connectEvent(eventName, newValue)
		else
			virtualNode.eventManager:connectPropertyChange(eventName, newValue)
		end

		return
	end

	local newIsBinding = Type.of(newValue) == Type.Binding
	local oldIsBinding = Type.of(oldValue) == Type.Binding

	if oldIsBinding then
		removeBinding(virtualNode, key)
	end

	if newIsBinding then
		attachBinding(virtualNode, key, newValue)
	else
		setRobloxInstanceProperty(virtualNode.hostObject, key, newValue)
	end
end

local RobloxRenderer = {}

function RobloxRenderer.isHostObject(target)
	return typeof(target) == "Instance"
end

function RobloxRenderer.mountHostNode(reconciler, virtualNode)
	local element = virtualNode.currentElement
	local hostParent = virtualNode.hostParent
	local hostKey = virtualNode.hostKey

	assert(ElementKind.of(element) == ElementKind.Host)

	-- TODO: Better error messages
	assert(element.props.Name == nil)
	assert(element.props.Parent == nil)

	local instance = Instance.new(element.component)
	virtualNode.hostObject = instance

	for propKey, value in pairs(element.props) do
		applyProp(virtualNode, propKey, value, nil)
	end

	instance.Name = hostKey

	local children = element.props[Children]

	reconciler.updateVirtualNodeChildren(virtualNode, virtualNode.hostObject, children)

	instance.Parent = hostParent
	virtualNode.hostObject = instance

	applyRef(element.props[Ref], instance)

	-- Enable event handling only when we're done with mounting
	if virtualNode.eventManager ~= nil then
		virtualNode.eventManager:resume()
	end
end

function RobloxRenderer.unmountHostNode(reconciler, virtualNode)
	local element = virtualNode.currentElement

	applyRef(element.props[Ref], nil)

	for _, childNode in pairs(virtualNode.children) do
		reconciler.unmountVirtualNode(childNode)
	end

	detachAllBindings(virtualNode)

	virtualNode.hostObject:Destroy()
end

function RobloxRenderer.updateHostNode(reconciler, virtualNode, newElement)
	local oldProps = virtualNode.currentElement.props
	local newProps = newElement.props

	-- Suspend event listeners for the node so we don't get events firing during reconciliation
	if virtualNode.eventManager ~= nil then
		virtualNode.eventManager:suspend()
	end

	-- If refs changed, detach the old ref and attach the new one
	if oldProps[Ref] ~= newProps[Ref] then
		applyRef(oldProps[Ref], nil)
		applyRef(newProps[Ref], virtualNode.hostObject)
	end

	-- Apply props that were added or updated
	for propKey, newValue in pairs(newProps) do
		local oldValue = oldProps[propKey]

		applyProp(virtualNode, propKey, newValue, oldValue)
	end

	-- Clean up props that were removed
	for propKey, oldValue in pairs(oldProps) do
		local newValue = newProps[propKey]

		if newValue == nil then
			applyProp(virtualNode, propKey, nil, oldValue)
		end
	end

	reconciler.updateVirtualNodeChildren(virtualNode, virtualNode.hostObject, newElement.props[Children])

	-- Resume event firing now that everything's updated successfully
	if virtualNode.eventManager ~= nil then
		virtualNode.eventManager:resume()
	end

	return virtualNode
end

return RobloxRenderer