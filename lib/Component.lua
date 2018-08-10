local Type = require(script.Parent.Type)
local ChildUtils = require(script.Parent.ChildUtils)

local componentClassMetatable = {}

function componentClassMetatable:__tostring()
	return self.__componentName
end

local Component = {}
setmetatable(Component, componentClassMetatable)

Component[Type] = Type.StatefulComponentClass
Component.__index = Component
Component.__componentName = "Component"

function Component:extend(name)
	assert(Type.of(self) == Type.StatefulComponentClass)
	assert(typeof(name) == "string")

	local class = {}

	for key, value in pairs(Component) do
		if key ~= "extend" then
			class[key] = value
		end
	end

	class[Type] = Type.StatefulComponentClass
	class.__index = class
	class.__componentName = name

	setmetatable(class, componentClassMetatable)

	return class
end

function Component:setState(mapState)
	assert(Type.of(self) == Type.StatefulComponentInstance)

	error("NYI")
end

function Component:getElementTraceback()
	return self.__internal.element.source
end

function Component:render()
	local message = (
		"The component %q is missing the `render` method.\n" ..
		"`render` must be defined when creating a Roact component!"
	):format(
		tostring(getmetatable(self))
	)

	error(message, 0)
end

function Component:__mount(reconciler, node)
	assert(Type.of(self) == Type.StatefulComponentClass)
	assert(reconciler ~= nil)
	assert(Type.of(node) == Type.Node)

	local element = node.currentElement
	local hostParent = node.hostParent
	local key = node.key

	local internal = {
		reconciler = reconciler,
		node = node,
		element = element,
	}

	local instance = {
		[Type] = Type.StatefulComponentInstance,
		__internal = internal,
	}

	setmetatable(instance, self)

	node.instance = instance

	-- TODO: defaultProps
	-- TODO: getDerivedStateFromProps

	instance.props = element.props
	instance.state = {}

	if instance.init ~= nil then
		instance:init(instance.props)
	end

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

		internal.element = updatedElement

		-- TODO: defaultProps
	end

	if updatedState ~= nil then
		newState = updatedState
	end

	-- TODO: getDerivedStateFromProps

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

return Component