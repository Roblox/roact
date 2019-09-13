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

local function getComponentFromVirtualNode(virtualNode)
	local element = virtualNode.currentElement
	local kind = ElementKind.of(element)

	if kind == ElementKind.Host
		or kind == ElementKind.Function
		or kind == ElementKind.Stateful
	then
		return element.component
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

	local internalData = {
		virtualNode = virtualNode,
		childrenMaxDepth = maxDepth - 1,
		virtualNodeChildren = maxDepth == 0 and {} or virtualNode.children,
		instance = virtualNode.hostObject,
	}

	local wrapper = {
		[InternalData] = internalData,
		component = getComponentFromVirtualNode(virtualNode),
		props = filterProps(virtualNode.currentElement.props),
		hostKey = virtualNode.hostKey,
		children = {},
	}

	for _, childVirtualNode in pairs(internalData.virtualNodeChildren) do
		getChildren(childVirtualNode, wrapper.children, internalData.childrenMaxDepth)
	end

	return setmetatable(wrapper, ShallowWrapperMetatable)
end

function ShallowWrapperPublic:find(constraints)
	VirtualNodeConstraints.validate(constraints)

	local results = {}

	for i=1, #self.children do
		local childWrapper = self.children[i]
		local childInternalData = childWrapper[InternalData]

		if VirtualNodeConstraints.satisfiesAll(childInternalData.virtualNode, constraints) then
			table.insert(results, childWrapper)
		end
	end

	return results
end

function ShallowWrapperPublic:findUnique(constraints)
	if constraints == nil then
		assert(
			#self.children == 1,
			("expect to contain exactly one child, but found %d"):format(#self.children)
		)
		return self.children[1]
	end

	local constrainedChildren = self:find(constraints)

	assert(
		#constrainedChildren == 1,
		("expect to find only one child, but found %d"):format(#constrainedChildren)
	)

	return constrainedChildren[1]
end

function ShallowWrapperPublic:getHostObject()
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