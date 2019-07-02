local createReconciler = require(script.Parent.createReconciler)
local RobloxRenderer = require(script.Parent.RobloxRenderer)
local ElementKind = require(script.Parent.ElementKind)
local ElementUtils = require(script.Parent.ElementUtils)

local robloxReconciler = createReconciler(RobloxRenderer)

local function getTypeFromVirtualNode(virtualNode)
	local element = virtualNode.currentElement
	local kind = ElementKind.of(element)

	if kind == ElementKind.Host then
		return {
			kind = ElementKind.Host,
			className = element.component,
		}
	elseif kind == ElementKind.Function then
		return {
			kind = ElementKind.Function,
			functionComponent = element.component,
		}
	elseif kind == ElementKind.Stateful then
		return {
			kind = ElementKind.Stateful,
			component = element.component,
		}
	else
		error('>>> unkown element ' .. tostring(kind))
	end
end

local ShallowWrapper = {}
local ShallowWrapperMetatable = {
	__index = ShallowWrapper,
}

function ShallowWrapper.new(virtualNode)
	local wrapper = {
		_virtualNode = virtualNode,
		type = getTypeFromVirtualNode(virtualNode),
		props = virtualNode.currentElement.props,
	}

	return setmetatable(wrapper, ShallowWrapperMetatable)
end

function ShallowWrapper:childrenCount()
	local count = 0

	for _ in pairs(self._virtualNode.children) do
		count = count + 1
	end

	return count
end

function ShallowWrapper:find(constraints)
	local results = {}

	for _, child in pairs(self._virtualNode.children) do
		if self:_satisfiesAllContraints(child, constraints) then
			table.insert(results, ShallowWrapper.new(child))
		end
	end

	return results
end

function ShallowWrapper:_satisfiesAllContraints(virtualNode, constraints)
	for constraint, value in pairs(constraints) do
		if not self:_satisfiesConstraint(virtualNode, constraint, value) then
			return false
		end
	end

	return true
end

function ShallowWrapper:_satisfiesConstraint(virtualNode, constraint, value)
	local element = virtualNode.currentElement

	if constraint == "kind" then
		return ElementKind.of(element) == value

	elseif constraint == "className" then
		local isHost = ElementKind.of(element) == ElementKind.Host
		return isHost and element.component == value

	elseif constraint == "component" then
		return element.component == value

	elseif constraint == "props" then
		local elementProps = element.props

		for propKey, propValue in pairs(value) do
			if elementProps[propKey] ~= propValue then
				return false
			end
		end

		return true
	else
		error(('unknown constraint %q'):format(constraint))
	end
end

local function shallow(element, options)
	options = options or {}

	local tempParent = Instance.new("Folder")
	local virtualNode = robloxReconciler.mountVirtualNode(element, tempParent, "ShallowTree")

	local maxDepth = options.depth or 1
	local currentDepth = 0

	local nextNode = virtualNode
	local wrapVirtualNode

	repeat
		wrapVirtualNode = nextNode
		nextNode = wrapVirtualNode.children[ElementUtils.UseParentKey]
		currentDepth = currentDepth + 1
	until currentDepth > maxDepth or nextNode == nil

	return ShallowWrapper.new(wrapVirtualNode)
end

return shallow