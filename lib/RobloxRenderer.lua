--[[
	Renderer that deals in terms of Roblox Instances. This is the most
	well-supported renderer after NoopRenderer and is currently the only
	renderer that does anything.
]]

local ElementKind = require(script.Parent.ElementKind)
local getDefaultPropertyValue = require(script.Parent.getDefaultPropertyValue)
local Type = require(script.Parent.Type)
local Children = require(script.Parent.PropMarkers.Children)
local Ref = require(script.Parent.PropMarkers.Ref)

local function setHostProperty(virtualNode, key, newValue, oldValue)
	if newValue == oldValue then
		return
	end

	if typeof(key) == "string" then
		if newValue == nil then
			local hostClass = virtualNode.hostObject.ClassName
			local _, defaultValue = getDefaultPropertyValue(hostClass, key)
			newValue = defaultValue
		end

		-- TODO: Handle errors from Roblox setting unknown keys on instances
		virtualNode.hostObject[key] = newValue
		return
	end

	if key == Children or key == Ref then
		-- Children and refs are handled elsewhere in the renderer
		return
	end

	local internalKeyType = Type.of(key)

	if internalKeyType == Type.HostEvent or internalKeyType == Type.HostChangeEvent then
		-- Event connections are handled in a separate pass
		return
	end

	-- TODO: Better error message
	error(("Unknown prop %q"):format(tostring(key)))
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
		setHostProperty(virtualNode, propKey, value, nil)
	end

	instance.Name = hostKey

	local children = element.props[Children]

	reconciler.mountVirtualNodeChildren(virtualNode, virtualNode.hostObject, children)

	instance.Parent = hostParent
	virtualNode.hostObject = instance

	-- TODO: Attach ref
end

function RobloxRenderer.unmountHostNode(reconciler, virtualNode)
	-- TODO: Detach ref

	for _, childNode in pairs(virtualNode.children) do
		reconciler.unmountVirtualNode(childNode)
	end

	virtualNode.hostObject:Destroy()
end

function RobloxRenderer.updateHostNode(reconciler, virtualNode, newElement)
	local oldProps = virtualNode.currentElement.props
	local newProps = newElement.props

	-- Apply props that were added or updated
	for propKey, newValue in pairs(newProps) do
		local oldValue = oldProps[propKey]

		if newValue ~= oldValue then
			setHostProperty(virtualNode, propKey, newValue, oldValue)
		end
	end

	-- Apply props that were removed
	for propKey, oldValue in pairs(oldProps) do
		local newValue = newProps[propKey]

		if newValue == nil then
			setHostProperty(virtualNode, propKey, nil, oldValue)
		end
	end

	reconciler.updateVirtualNodeChildren(virtualNode, virtualNode.hostObject, newElement.props[Children])

	return virtualNode
end

return RobloxRenderer