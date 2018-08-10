local Type = require(script.Parent.Type)
local ChildUtils = require(script.Parent.ChildUtils)

local Component = {}
Component[Type] = Type.StatefulComponentClass
Component.__index = Component

function Component:extend(name)
	assert(typeof(name) == "string")

	local class = {}
	class[Type] = Type.StatefulComponentInstance
	class.__index = class

	for key, value in pairs(Component) do
		if key ~= "extend" then
			class[key] = value
		end
	end

	return class
end

function Component:__mount(reconciler, node)
	assert(Type.of(self) == Type.StatefulComponentClass)
	assert(reconciler ~= nil)
	assert(Type.of(node) == Type.Node)

	local hostParent = node.hostParent
	local key = node.key

	local internal = {
		reconciler = reconciler,
		node = node,
	}

	local instance = {
		__internal = internal,
	}

	setmetatable(instance, self)

	node.instance = instance

	local renderResult = instance:render()

	for childKey, childElement in ChildUtils.iterateChildren(renderResult) do
		if childKey == ChildUtils.UseParentKey then
			childKey = key
		end

		local childNode = reconciler.mountNode(childElement, hostParent, childKey)

		node.children[childKey] = childNode
	end

	if instance.didMount ~= nil then
		instance:didMount()
	end
end

function Component:__unmount()
	assert(Type.of(self) == Type.StatefulComponentInstance)

	local internal = self.__internal
	local node = internal.node
	local reconciler = internal.reconciler

	if self.willUnmount ~= nil then
		self:willUnmount()
	end

	for _, childNode in pairs(node.children) do
		reconciler.unmountNode(childNode)
	end
end

function Component:__update(updatedElement, updatedState)
	assert(Type.of(self) == Type.StatefulComponentInstance)
	assert(Type.of(updatedElement) == Type.Element or updatedElement == nil)
	assert(typeof(updatedState) == "table" or updatedState == nil)

	local internal = self.__internal
	local node = internal.node
	local reconciler = internal.reconciler

	local oldProps = self.props
	local oldState = self.state

	local newProps = oldProps
	local newState = oldState

	if updatedElement ~= nil then
		newProps = updatedElement.props

		-- TODO: defaultProps
		-- TODO: getDerivedStateFromProps
	end

	if updatedState ~= nil then
		newState = updatedState
	end

	if self.willUpdate ~= nil then
		self:willUpdate(newProps, newState)
	end

	self.props = newProps
	self.state = newState

	local renderResult = node.instance:render()

	reconciler.updateNodeChildren(node, renderResult)

	if self.didUpdate ~= nil then
		self:didUpdate(oldProps, oldState)
	end
end

function Component:render()
	error("overwrite render please")
end

return Component