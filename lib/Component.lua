local assign = require(script.Parent.assign)
local Type = require(script.Parent.Type)
local Symbol = require(script.Parent.Symbol)
local invalidSetStateMessages = require(script.Parent.invalidSetStateMessages)

local InternalData = Symbol.named("InternalData")

local componentMissingRenderMessage = [[
The component %q is missing the `render` method.
`render` must be defined when creating a Roact component!]]

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

	local internalData = self[InternalData]

	-- This value will be set when we're in a place that `setState` should not
	-- be used. It will be set to the name of a message to display to the user.
	if internalData.setStateBlockedReason ~= nil then
		local messageTemplate = invalidSetStateMessages[internalData.setStateBlockedReason]

		if messageTemplate == nil then
			messageTemplate = invalidSetStateMessages.default
		end

		local message = messageTemplate:format(tostring(internalData.componentClass))

		error(message, 2)
	end

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

	-- If `setState` is called in `init`, we can skip triggering an update!
	if internalData.setStateShouldSkipUpdate then
		self.state = newState
	else
		self:__update(nil, newState)
	end
end

--[[
	Returns the stack trace of where the element was created that this component
	instance's properties are based on.

	Intended to be used primarily by diagnostic tools.
]]
function Component:getElementTraceback()
	return self[InternalData].virtualNode.currentElement.source
end

--[[
	Returns a snapshot of this component given the current props and state. Must
	be overriden by consumers of Roact and should be a pure function with
	regards to props and state.

	TODO: Accept props and state as arguments.
]]
function Component:render()
	local internalData = self[InternalData]

	local message = componentMissingRenderMessage:format(
		tostring(internalData.componentClass)
	)

	error(message, 0)
end

--[[
	Tries to update the component's children, correctly handling the presence of
	an error boundary.
]]
function Component:__updateChildren(reconciler, virtualNode)
	local hostParent = virtualNode.hostParent
	local instance = virtualNode.instance
	local internalData = instance[InternalData]

	internalData.setStateBlockedReason = "render"
	local renderResult = instance:render()
	internalData.setStateBlockedReason = nil

	-- Only bother with pcall if we actually have something to handle the error.
	if self.getDerivedStateFromError ~= nil then
		local success, message = pcall(reconciler.updateVirtualNodeWithRenderResult, virtualNode, hostParent, renderResult)

		if not success then
			local stateDelta = self.getDerivedStateFromError(message)
			-- Use setState here to preserve any semantics that setState has.
			-- This also means getDerivedStateFromError can return a mapper
			-- function, not just a delta table.
			internalData.setStateShouldSkipUpdate = true
			instance:setState(stateDelta)
			internalData.setStateShouldSkipUpdate = false

			internalData.setStateBlockedReason = "render"
			renderResult = instance:render()
			internalData.setStateBlockedReason = nil
			-- Don't try to handle errors at this point - the component should
			-- be in a position to render a non-throwing fallback by now.
			reconciler.updateVirtualNodeWithRenderResult(virtualNode, hostParent, renderResult)
		end
	else
		reconciler.updateVirtualNodeWithRenderResult(virtualNode, hostParent, renderResult)
	end
end

--[[
	An internal method used by the reconciler to construct a new component
	instance and attach it to the given virtualNode.
]]
function Component:__mount(reconciler, virtualNode)
	assert(Type.of(self) == Type.StatefulComponentClass)
	assert(reconciler ~= nil)
	assert(Type.of(virtualNode) == Type.VirtualNode)

	local currentElement = virtualNode.currentElement

	-- Contains all the information that we want to keep from consumers of
	-- Roact, or even other parts of the codebase like the reconciler.
	local internalData = {
		reconciler = reconciler,
		virtualNode = virtualNode,
		componentClass = self,

		setStateBlockedReason = nil,
		setStateShouldSkipUpdate = false,
	}

	local instance = {
		[Type] = Type.StatefulComponentInstance,
		[InternalData] = internalData,
	}

	setmetatable(instance, self)

	virtualNode.instance = instance

	local props = currentElement.props

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

	local newContext = assign({}, virtualNode.context)
	instance._context = newContext

	if instance.init ~= nil then
		internalData.setStateShouldSkipUpdate = true
		instance:init(instance.props)
		internalData.setStateShouldSkipUpdate = false
	end

	-- It's possible for init() to redefine _context!
	virtualNode.context = instance._context

	self:__updateChildren(reconciler, virtualNode)

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
	local virtualNode = internalData.virtualNode
	local reconciler = internalData.reconciler

	-- TODO: Set unmounted flag to disallow setState after this point

	if self.willUnmount ~= nil then
		internalData.setStateBlockedReason = "willUnmount"
		self:willUnmount()
		internalData.setStateBlockedReason = nil
	end

	for _, childNode in pairs(virtualNode.children) do
		reconciler.unmountVirtualNode(childNode)
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
	local virtualNode = internalData.virtualNode
	local reconciler = internalData.reconciler
	local componentClass = internalData.componentClass

	local oldProps = self.props
	local oldState = self.state

	-- These will be updated based on `updatedElement` and `updatedState`
	local newProps = oldProps
	local newState = oldState

	if updatedElement ~= nil then
		newProps = updatedElement.props

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

			newState = assign({}, newState, derivedState)
		end
	end

	if self.shouldUpdate ~= nil then
		internalData.setStateBlockedReason = "shouldUpdate"
		local continueWithUpdate = self:shouldUpdate(newProps, newState)
		internalData.setStateBlockedReason = nil

		if not continueWithUpdate then
			return false
		end
	end

	if self.willUpdate ~= nil then
		internalData.setStateBlockedReason = "willUpdate"
		self:willUpdate(newProps, newState)
		internalData.setStateBlockedReason = nil
	end

	self.props = newProps
	self.state = newState

	self:__updateChildren(reconciler, virtualNode)

	if self.didUpdate ~= nil then
		self:didUpdate(oldProps, oldState)
	end

	return true
end

return Component