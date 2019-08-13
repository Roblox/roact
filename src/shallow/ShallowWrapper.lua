local RoactRoot = script.Parent.Parent

local Children = require(RoactRoot.PropMarkers.Children)
local ElementKind = require(RoactRoot.ElementKind)
local ElementUtils = require(RoactRoot.ElementUtils)
local strict = require(RoactRoot.strict)
local Symbol = require(RoactRoot.Symbol)
local Snapshot = require(script.Parent.Snapshot)
local VirtualNodeConstraints = require(script.Parent.VirtualNodeConstraints)

local InternalData = Symbol.named("InternalData")

local ShallowWrapper = {}
local ShallowWrapperPublic = {}
local ShallowWrapperMetatable = {
	__index = ShallowWrapperPublic,
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
		error(("shallow wrapper does not support element of kind %q"):format(tostring(kind)))
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
		[InternalData] = {
			virtualNode = virtualNode,
			childrenMaxDepth = maxDepth - 1,
			virtualNodeChildren = maxDepth == 0 and {} or virtualNode.children,
			instance = virtualNode.hostObject,
		},
		type = getTypeFromVirtualNode(virtualNode),
		props = filterProps(virtualNode.currentElement.props),
		hostKey = virtualNode.hostKey,
	}

	return setmetatable(wrapper, ShallowWrapperMetatable)
end

function ShallowWrapperPublic:childrenCount()
	local count = 0
	local internalData = self[InternalData]

	for _, virtualNode in pairs(internalData.virtualNodeChildren) do
		local element = virtualNode.currentElement
		count = count + countChildrenOfElement(element)
	end

	return count
end

function ShallowWrapperPublic:find(constraints)
	VirtualNodeConstraints.validate(constraints)

	local results = {}
	local children = self:getChildren()

	for i=1, #children do
		local childWrapper = children[i]
		local childInternalData = childWrapper[InternalData]

		if VirtualNodeConstraints.satisfiesAll(childInternalData.virtualNode, constraints) then
			table.insert(results, childWrapper)
		end
	end

	return results
end

function ShallowWrapperPublic:findUnique(constraints)
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

function ShallowWrapperPublic:getChildren()
	local results = {}
	local internalData = self[InternalData]

	for _, childVirtualNode in pairs(internalData.virtualNodeChildren) do
		getChildren(childVirtualNode, results, internalData.childrenMaxDepth)
	end

	return results
end

function ShallowWrapperPublic:getInstance()
	local internalData = self[InternalData]

	return internalData.instance
end

function ShallowWrapperPublic:matchSnapshot(identifier)
	assert(typeof(identifier) == "string", "Snapshot identifier must be a string")

	local snapshotResult = Snapshot.createMatcher(identifier, self)

	snapshotResult:match()
end

function ShallowWrapperPublic:toSnapshotString()
	return Snapshot.toString(self)
end

strict(ShallowWrapperPublic, "ShallowWrapper")

return strict(ShallowWrapper, "ShallowWrapper")