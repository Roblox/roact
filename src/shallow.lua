local createReconciler = require(script.Parent.createReconciler)
local Children = require(script.Parent.PropMarkers.Children)
local RobloxRenderer = require(script.Parent.RobloxRenderer)
local ElementKind = require(script.Parent.ElementKind)
local ElementUtils = require(script.Parent.ElementUtils)

local robloxReconciler = createReconciler(RobloxRenderer)

local ShallowWrapper = {}
local ShallowWrapperMetatable = {
	__index = ShallowWrapper,
}

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
		error(('shallow wrapper does not support element of kind %q'):format(tostring(kind)))
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
	kind = function(element, expectKind)
		return ElementKind.of(element) == expectKind
	end,
	className = function(element, className)
		local isHost = ElementKind.of(element) == ElementKind.Host
		return isHost and element.component == className
	end,
	component = function(element, expectComponentValue)
		return element.component == expectComponentValue
	end,
	props = function(element, propSubSet)
		local elementProps = element.props

		for propKey, propValue in pairs(propSubSet) do
			if elementProps[propKey] ~= propValue then
				return false
			end
		end

		return true
	end
}

local function countChildrenOfElement(element)
	if ElementKind.of(element) == ElementKind.Fragment then
		local count = 0

		for _, subElement in pairs(element.elements) do
			count = count + countChildrenOfElement(subElement)
		end

		return count
	else
		return 1
	end
end

local function getChildren(virtualNode, results, maxDepth)
	if ElementKind.of(virtualNode.currentElement) == ElementKind.Fragment then
		for _, subVirtualNode in pairs(virtualNode.children) do
			getChildren(subVirtualNode, results, maxDepth)
		end
	else
		local childWrapper = ShallowWrapper.new(
			virtualNode,
			maxDepth
		)

		table.insert(results, childWrapper)
	end
end

local function filterProps(props)
	if props[Children] == nil then
		return props
	end

	local filteredProps = {}

	for key, value in pairs(props) do
		if key ~= Children then
			props[key] = value
		end
	end

	return filteredProps
end

function ShallowWrapper.new(virtualNode, maxDepth)
	virtualNode = findNextVirtualNode(virtualNode, maxDepth)

	local wrapper = {
		_virtualNode = virtualNode,
		_childrenMaxDepth = maxDepth - 1,
		_virtualNodeChildren = maxDepth == 0 and {} or virtualNode.children,
		_shallowChildren = nil,
		type = getTypeFromVirtualNode(virtualNode),
		props = filterProps(virtualNode.currentElement.props),
	}

	return setmetatable(wrapper, ShallowWrapperMetatable)
end

function ShallowWrapper:childrenCount()
	local count = 0

	for _, virtualNode in pairs(self._virtualNodeChildren) do
		local element = virtualNode.currentElement
		count = count + countChildrenOfElement(element)
	end

	return count
end

function ShallowWrapper:find(constraints)
	for constraint in pairs(constraints) do
		if not ContraintFunctions[constraint] then
			error(('unknown constraint %q'):format(constraint))
		end
	end

	local results = {}
	local children = self:getChildren()

	for i=1, #children do
		local childWrapper = children[i]
		if childWrapper:_satisfiesAllContraints(constraints) then
			table.insert(results, childWrapper)
		end
	end

	return results
end

function ShallowWrapper:getChildren()
	if self._shallowChildren then
		return self._shallowChildren
	end

	local results = {}

	for _, childVirtualNode in pairs(self._virtualNodeChildren) do
		getChildren(childVirtualNode, results, self._childrenMaxDepth)
	end

	self._shallowChildren = results
	return results
end

function ShallowWrapper:_satisfiesAllContraints(constraints)
	local element = self._virtualNode.currentElement

	for constraint, value in pairs(constraints) do
		local constraintFunction = ContraintFunctions[constraint]

		if not constraintFunction(element, value) then
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