local assign = require(script.Parent.assign)
local Type = require(script.Parent.Type)
local ChildUtils = require(script.Parent.ChildUtils)
local Symbol = require(script.Parent.Symbol)

local InternalData = Symbol.named("InternalData")

local componentClassMetatable = {}

function componentClassMetatable:__tostring()
	return self.__componentName
end

local Component = {}
setmetatable(Component, componentClassMetatable)

Component[Type] = Type.StatefulComponentClass
Component.__index = Component
Component.__componentName = "Component"

--[[
	A method called by consumers of Roact to create a new component class.
	Components can not be extended beyond this point, with the exception of
	PureComponent.
]]
function Component:extend(name)
	assert(Type.of(self) == Type.StatefulComponentClass)
	assert(typeof(name) == "string")

	local class = {}

	for key, value in pairs(self) do
		-- Roact opts to make consumers use composition over inheritance, which
		-- lines up with React.
		-- https://reactjs.org/docs/composition-vs-inheritance.html
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

	-- TODO: Do something different in init and willUpdate
	-- TODO: Throw errors in render and shouldUpdate

	local partialState

	if typeof(mapState) == "function" then
		partialState = mapState(self.state, self.props)

		if partialState == nil then
			return
		end
	elseif typeof(mapState) == "table" then
		partialState = mapState
	else
		error("Invalid argument to setState, expected function or table", 2)
	end

	local newState = assign({}, self.state, partialState)

	self:__update(nil, newState)
end

--[[
	Returns the stack trace of where the element was created that this component
	instance's properties are based on.

	Intended to be used primarily by diagnostic tools.
]]
function Component:getElementTraceback()
	return self[InternalData].element.source
end

--[[
	Returns a snapshot of this component given the current props and state. Must
	be overriden by consumers of Roact and should be a pure function with
	regards to props and state.

	TODO: Accept props and state as arguments.
]]
function Component:render()
	local message = (
		"The component %q is missing the `render` method.\n" ..
		"`render` must be defined when creating a Roact component!"
	):format(
		tostring(getmetatable(self))
	)

	error(message, 0)
end

--[[
	An internal method used by the reconciler to construct a new component
	instance and attach it to the given node.
]]
function Component:__mount(reconciler, node)
	assert(Type.of(self) == Type.StatefulComponentClass)
	assert(reconciler ~= nil)
	assert(Type.of(node) == Type.Node)

	local element = node.currentElement
	local hostParent = node.hostParent
	local key = node.key

	-- Contains all the information that we want to keep from consumers of
	-- Roact, or even other parts of the codebase like the reconciler.
	local internalData = {
		reconciler = reconciler,
		node = node,
		element = element,
		componentClass = self,
	}

	local instance = {
		[Type] = Type.StatefulComponentInstance,
		[InternalData] = internalData,
	}

	setmetatable(instance, self)

	node.instance = instance

	local props = element.props

	if self.defaultProps ~= nil then
		props = assign({}, self.defaultProps, props)
	end

	instance.props = props
	instance.state = {}

	if self.getDerivedStateFromProps ~= nil then
		local derivedState = self.getDerivedStateFromProps(instance.props, instance.state)

		if derivedState ~= nil then
			assert(typeof(derivedState) == "table", "getDerivedStateFromProps must return a table!")

			assign(instance.state, derivedState)
		end
	end

	if instance.init ~= nil then
		-- TODO: Change behavior of setState here to match master branch.
		instance:init(instance.props)
	end

	local renderResult = instance:render()

	for childKey, childElement in ChildUtils.iterateChildren(renderResult) do
		local concreteKey = childKey
		if childKey == ChildUtils.UseParentKey then
			concreteKey = key
		end

		local childNode = reconciler.mountNode(childElement, hostParent, concreteKey)

		node.children[childKey] = childNode
	end

	if instance.didMount ~= nil then
		instance:didMount()
	end
end

--[[
	Internal method used by the reconciler to clean up any resources held by
	this component instance.
]]
function Component:__unmount()
	assert(Type.of(self) == Type.StatefulComponentInstance)

	local internalData = self[InternalData]
	local node = internalData.node
	local reconciler = internalData.reconciler

	if self.willUnmount ~= nil then
		self:willUnmount()
	end

	for _, childNode in pairs(node.children) do
		reconciler.unmountNode(childNode)
	end
end

--[[
	Internal method used by `setState` and the reconciler to update the
	component instance.

	Both `updatedElement` and `updatedState` are optional and indicate different
	kinds of updates. Both may be supplied to update props and state in a single
	pass, as in the case of a batched update.
]]
function Component:__update(updatedElement, updatedState)
	assert(Type.of(self) == Type.StatefulComponentInstance)
	assert(Type.of(updatedElement) == Type.Element or updatedElement == nil)
	assert(typeof(updatedState) == "table" or updatedState == nil)

	local internalData = self[InternalData]
	local node = internalData.node
	local reconciler = internalData.reconciler
	local componentClass = internalData.componentClass

	local oldProps = self.props
	local oldState = self.state

	-- These will be updated based on `updatedElement` and `updatedState`
	local newProps = oldProps
	local newState = oldState

	if updatedElement ~= nil then
		newProps = updatedElement.props

		internalData.element = updatedElement

		if componentClass.defaultProps ~= nil then
			newProps = assign({}, componentClass.defaultProps, newProps)
		end
	end

	if updatedState ~= nil then
		newState = updatedState
	end

	if componentClass.getDerivedStateFromProps ~= nil then
		local derivedState = componentClass.getDerivedStateFromProps(newProps, newState)

		if derivedState ~= nil then
			assert(typeof(derivedState) == "table", "getDerivedStateFromProps must return a table!")

			assign(updatedState, derivedState)
		end
	end

	if self.shouldUpdate ~= nil then
		if not self:shouldUpdate(newProps, newState) then
			-- TODO: Do we need to reset internalData.element so that
			-- getElementTraceback stays correct?
			return
		end
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

return Component