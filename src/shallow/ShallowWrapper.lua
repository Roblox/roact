local RoactRoot = script.Parent.Parent

local Children = require(RoactRoot.PropMarkers.Children)
local ElementKind = require(RoactRoot.ElementKind)
local ElementUtils = require(RoactRoot.ElementUtils)
local VirtualNodeConstraints = require(script.Parent.VirtualNodeConstraints)
local Snapshot = require(script.Parent.Snapshot)

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
	local currentNode = virtualNode
	local nextNode = currentNode.children[ElementUtils.UseParentKey]

	while currentDepth < maxDepth and nextNode ~= nil do
		currentNode = nextNode
		nextNode = currentNode.children[ElementUtils.UseParentKey]
		currentDepth = currentDepth + 1
	end

	return currentNode
end

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
			filteredProps[key] = value
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
		type = getTypeFromVirtualNode(virtualNode),
		props = filterProps(virtualNode.currentElement.props),
		hostKey = virtualNode.hostKey,
		instance = virtualNode.hostObject,
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
	VirtualNodeConstraints.validate(constraints)

	local results = {}
	local children = self:getChildren()

	for i=1, #children do
		local childWrapper = children[i]

		if VirtualNodeConstraints.satisfiesAll(childWrapper._virtualNode, constraints) then
			table.insert(results, childWrapper)
		end
	end

	return results
end

function ShallowWrapper:findUnique(constraints)
	local children = self:getChildren()

	if constraints == nil then
		assert(
			#children == 1,
			("expect to contain exactly one child, but found %d"):format(#children)
		)
		return children[1]
	end

	local constrainedChildren = self:find(constraints)

	assert(
		#constrainedChildren == 1,
		("expect to find only one child, but found %d"):format(#constrainedChildren)
	)

	return constrainedChildren[1]
end

function ShallowWrapper:getChildren()
	local results = {}

	for _, childVirtualNode in pairs(self._virtualNodeChildren) do
		getChildren(childVirtualNode, results, self._childrenMaxDepth)
	end

	return results
end

function ShallowWrapper:matchSnapshot(identifier)
	assert(typeof(identifier) == "string", "Snapshot identifier must be a string")

	local snapshotResult = Snapshot.createMatcher(identifier, self)

	snapshotResult:match()
end

function ShallowWrapper:snapshotToString()
	return Snapshot.toString(self)
end

return ShallowWrapper