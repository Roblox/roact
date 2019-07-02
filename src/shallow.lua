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
		error(('shallow wrapper does not support element of kind %q'):format(kind))
	end
end

local function findNextVirtualNode(virtualNode, maxDepth)
	local currentDepth = 0
	local wrapVirtualNode = virtualNode
	local nextNode = wrapVirtualNode.children[ElementUtils.UseParentKey]

	while currentDepth < maxDepth and nextNode ~= nil do
		wrapVirtualNode = nextNode
		nextNode = wrapVirtualNode.children[ElementUtils.UseParentKey]
		currentDepth = currentDepth + 1
	end

	return wrapVirtualNode
end

local ContraintFunctions = {
	kind = function(virtualNode, expectKind)
		return ElementKind.of(virtualNode.currentElement) == expectKind
	end,
	className = function(virtualNode, className)
		local element = virtualNode.currentElement
		local isHost = ElementKind.of(element) == ElementKind.Host
		return isHost and element.component == className
	end,
	component = function(virtualNode, expectComponentValue)
		return virtualNode.currentElement.component == expectComponentValue
	end,
	props = function(virtualNode, propSubSet)
		local elementProps = virtualNode.currentElement.props

		for propKey, propValue in pairs(propSubSet) do
			if elementProps[propKey] ~= propValue then
				return false
			end
		end

		return true
	end
}

local ShallowWrapper = {}
local ShallowWrapperMetatable = {
	__index = ShallowWrapper,
}

function ShallowWrapper.new(virtualNode, maxDepth)
	virtualNode = findNextVirtualNode(virtualNode, maxDepth)

	local wrapper = {
		_virtualNode = virtualNode,
		_childrenMaxDepth = maxDepth - 1,
		_children = maxDepth == 0 and {} or virtualNode.children,
		type = getTypeFromVirtualNode(virtualNode),
		props = virtualNode.currentElement.props,
	}

	return setmetatable(wrapper, ShallowWrapperMetatable)
end

function ShallowWrapper:childrenCount()
	local count = 0

	for _ in pairs(self._children) do
		count = count + 1
	end

	return count
end

function ShallowWrapper:find(constraints)
	local results = {}

	for constraint in pairs(constraints) do
		if not ContraintFunctions[constraint] then
			error(('unknown constraint %q'):format(constraint))
		end
	end

	for _, child in pairs(self._children) do
		local childWrapper = ShallowWrapper.new(child, self._childrenMaxDepth)

		if self:_satisfiesAllContraints(childWrapper._virtualNode, constraints) then
			table.insert(results, childWrapper)
		end
	end

	return results
end

function ShallowWrapper:_satisfiesAllContraints(virtualNode, constraints)
	for constraint, value in pairs(constraints) do
		local constraintFunction = ContraintFunctions[constraint]

		if not constraintFunction(virtualNode, value) then
			return false
		end
	end

	return true
end

local function shallow(element, options)
	options = options or {}

	local tempParent = Instance.new("Folder")
	local virtualNode = robloxReconciler.mountVirtualNode(element, tempParent, "ShallowTree")

	local maxDepth = options.depth or 1

	return ShallowWrapper.new(virtualNode, maxDepth)
end

return shallow