local assign = require(script.Parent.assign)
local Type = require(script.Parent.Type)
local Symbol = require(script.Parent.Symbol)
local invalidSetStateMessages = require(script.Parent.invalidSetStateMessages)

local InternalData = Symbol.named("InternalData")

local LifecyclePhase = {
	Init = "init",
	Render = "render",
	ShouldUpdate = "shouldUpdate",
	WillUpdate = "willUpdate",
	DidMount = "didMount",
	DidUpdate = "didUpdate",
	WillUnmount = "willUnmount",
	ReconcileChildren = "reconcileChildren",
	Done = "done",
}

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

function Component:__getDerivedState(incomingProps, incomingState)
	assert(Type.of(self) == Type.StatefulComponentInstance)

	local internalData = self[InternalData]
	local componentClass = internalData.componentClass
	if tostring(componentClass) == "Parent" then
		print(debug.traceback())
	end

	if componentClass.getDerivedStateFromProps ~= nil then
		local derivedState = componentClass.getDerivedStateFromProps(incomingProps, incomingState)

		if derivedState ~= nil then
			assert(typeof(derivedState) == "table", "getDerivedStateFromProps must return a table!")

			return derivedState
		end
	end

	return nil
end

function Component:setState(mapState)
	assert(Type.of(self) == Type.StatefulComponentInstance)

	local internalData = self[InternalData]
	local lifecyclePhase = internalData.lifecyclePhase

	--[[
		When preparing to update, rendering, or unmounting, it is not safe
		to call `setState` as it will interfere with in-flight updates. It's
		also disallowed during unmounting
	]]
	if lifecyclePhase == LifecyclePhase.ShouldUpdate or
		lifecyclePhase == LifecyclePhase.WillUpdate or
		lifecyclePhase == LifecyclePhase.Render or
		lifecyclePhase == LifecyclePhase.WillUnmount
	then
		local messageTemplate = invalidSetStateMessages[internalData.lifecyclePhase]

		if messageTemplate == nil then
			messageTemplate = invalidSetStateMessages["default"]
		end

		local message = messageTemplate:format(tostring(internalData.componentClass))

		error(message, 2)
	end

	local pendingUpdate = internalData.pendingStateUpdate

	local currentState
	if pendingUpdate ~= nil then
		-- FIXME: This approach is weird, but to resolve organization/sequence issues, this is actually
		-- deriving the OLD pending state only when new state is collapsed in. It's not impossible that
		-- the gap in time could make it so that the props passed in here are not the correct props
		-- that would have been passed in if the pending state was derived atomically at the moment
		-- it was provided.
		currentState = assign(pendingUpdate, self:__getDerivedState(self.props, pendingUpdate))
	else
		currentState = self.state
	end

	local stateUpdate
	if typeof(mapState) == "function" then
		stateUpdate = mapState(currentState, self.props)

		-- Abort the stateUpdate if the given state updater function returns nil
		if stateUpdate == nil then
			return nil
		end
	elseif typeof(mapState) == "table" then
		stateUpdate = mapState
	else
		error("Invalid argument to setState, expected function or table", 3)
	end

	-- FIXME: Compromising extra table creation here to avoid complexity, for now. Technically,
	-- currentState ~= self.state, we could assign directly onto it
	stateUpdate = assign({}, currentState, stateUpdate)

	if stateUpdate ~= nil then
		if lifecyclePhase == LifecyclePhase.Init then
			-- If `setState` is called in `init`, we can skip triggering an update!
			self.state = assign(stateUpdate, self:__getDerivedState(self.props, stateUpdate))

		elseif lifecyclePhase == LifecyclePhase.DidMount or
			lifecyclePhase == LifecyclePhase.DidUpdate or
			lifecyclePhase == LifecyclePhase.ReconcileChildren
		then
			--[[
				During certain phases of the component lifecycle, it's acceptable to
				allow `setState` but defer the update until we're done with ones in flight.
				We do this by collapsing it into any pending updates we have.
			]]
			internalData.pendingStateUpdate = stateUpdate

		else
			-- Since we're about to resolve any pending state we had, we clear it
			internalData.pendingStateUpdate = nil

			-- Outside of our lifecycle, the state update is safe to make
			self:__update(nil, stateUpdate)
		end
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
	be overridden by consumers of Roact and should be a pure function with
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
	An internal method used by the reconciler to construct a new component
	instance and attach it to the given virtualNode.
]]
function Component:__mount(reconciler, virtualNode)
	assert(Type.of(self) == Type.StatefulComponentClass)
	assert(reconciler ~= nil)
	assert(Type.of(virtualNode) == Type.VirtualNode)

	local currentElement = virtualNode.currentElement
	local hostParent = virtualNode.hostParent

	-- Contains all the information that we want to keep from consumers of
	-- Roact, or even other parts of the codebase like the reconciler.
	local internalData = {
		reconciler = reconciler,
		virtualNode = virtualNode,
		componentClass = self,
		lifecyclePhase = LifecyclePhase.Init,
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

	local newContext = assign({}, virtualNode.context)
	instance._context = newContext

	if instance.init ~= nil then
		instance:init(instance.props)
	end

	-- We allow users to define the initial state. If they don't, we'll do it.
	if instance.state == nil then
		instance.state = assign({}, instance:__getDerivedState(instance.props, {}))
	end

	-- It's possible for init() to redefine _context!
	virtualNode.context = instance._context

	internalData.lifecyclePhase = LifecyclePhase.Render
	local renderResult = instance:render()

	internalData.lifecyclePhase = LifecyclePhase.ReconcileChildren
	reconciler.updateVirtualNodeWithRenderResult(virtualNode, hostParent, renderResult)

	if instance.didMount ~= nil then
		internalData.lifecyclePhase = LifecyclePhase.DidMount
		instance:didMount()
	end

	if internalData.pendingStateUpdate ~= nil then
		local pendingState = internalData.pendingStateUpdate

		internalData.pendingStateUpdate = nil

		instance:__update(nil, pendingState)
	end

	internalData.lifecyclePhase = LifecyclePhase.Done
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
		internalData.lifecyclePhase = LifecyclePhase.WillUnmount
		self:willUnmount()
	end

	for _, childNode in pairs(virtualNode.children) do
		reconciler.unmountVirtualNode(childNode)
	end

	-- ?? not sure about this???
	internalData.lifecyclePhase = LifecyclePhase.Done
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

	if updatedState ~= nil or oldProps ~= newProps then
		updatedState = assign(updatedState, self:__getDerivedState(newProps, updatedState or oldState))
	end

	if updatedState ~= nil then
		newState = updatedState
	end

	-- During shouldUpdate, willUpdate, and render, setState calls are suspended
	if self.shouldUpdate ~= nil then
		internalData.lifecyclePhase = LifecyclePhase.ShouldUpdate
		local continueWithUpdate = self:shouldUpdate(newProps, newState)

		if not continueWithUpdate then
			return false
		end
	end

	if self.willUpdate ~= nil then
		internalData.lifecyclePhase = LifecyclePhase.WillUpdate
		self:willUpdate(newProps, newState)
	end

	self.props = newProps
	self.state = newState

	internalData.lifecyclePhase = LifecyclePhase.Render
	local renderResult = virtualNode.instance:render()

	internalData.lifecyclePhase = LifecyclePhase.ReconcileChildren
	reconciler.updateVirtualNodeWithRenderResult(virtualNode, virtualNode.hostParent, renderResult)

	if self.didUpdate ~= nil then
		internalData.lifecyclePhase = LifecyclePhase.DidUpdate
		self:didUpdate(oldProps, oldState)
	end

	if internalData.pendingStateUpdate ~= nil then
		local pendingState = internalData.pendingStateUpdate

		internalData.pendingStateUpdate = nil

		self:__update(nil, pendingState)
	end

	internalData.lifecyclePhase = LifecyclePhase.Done

	return true
end

return Component