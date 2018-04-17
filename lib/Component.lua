--[[
	The base component implementation that is extended by users of Roact.

	Exposed as Roact.Component
]]

local Reconciler = require(script.Parent.Reconciler)
local Core = require(script.Parent.Core)
local invalidSetStateMessages = require(script.Parent.invalidSetStateMessages)

local Component = {}

Component.__index = Component

local function mergeState(currentState, partialState)
	local newState = {}

	for key, value in pairs(currentState) do
		newState[key] = value
	end

	for key, value in pairs(partialState) do
		if value == Core.None then
			newState[key] = nil
		else
			newState[key] = value
		end
	end

	return newState
end

--[[
	Create a new Roact stateful component class.

	Not intended to be a general OO implementation, this function only intends
	to let users extend Component and PureComponent.

	Instead of using inheritance, use composition and props to extend components.
]]
function Component:extend(name)
	assert(type(name) == "string", "A name must be provided to create a Roact Component")

	local class = {}

	for key, value in pairs(self) do
		-- We don't want users using 'extend' to create component inheritance
		-- see https://reactjs.org/docs/composition-vs-inheritance.html
		if key ~= "extend" then
			class[key] = value
		end
	end

	class.__index = class

	setmetatable(class, {
		__tostring = function(self)
			return name
		end
	})

	function class._new(props, context)
		local self = {}

		-- When set to a value, setState will fail, using the given reason to
		-- create a detailed error message.
		-- You can see a list of reasons in invalidSetStateMessages.
		self._setStateBlockedReason = nil

		self.props = props
		self._context = {}

		-- Shallow copy all context values from our parent element.
		if context then
			for key, value in pairs(context) do
				self._context[key] = value
			end
		end

		setmetatable(self, class)

		-- Call the user-provided initializer, where state and _props are set.
		if class.init then
			self._setStateBlockedReason = "init"
			class.init(self, props)
			self._setStateBlockedReason = nil
		end

		-- The user constructer might not set state, so we can.
		if not self.state then
			self.state = {}
		end

		if class.getDerivedStateFromProps then
			local partialState = class.getDerivedStateFromProps(props, self.state)

			if partialState then
				self.state = mergeState(self.state, partialState)
			end
		end

		return self
	end

	return class
end

--[[
	Override this with a function that returns the elements that should
	represent this component with the current state.
]]
function Component:render()
	local message = (
		"The component %q is missing the 'render' method.\n" ..
		"render must be defined when creating a Roact component!"
	):format(
		tostring(getmetatable(self))
	)

	error(message, 0)
end

--[[
	Used to tell Roact whether this component *might* need to be re-rendered
	given a new set of props and state.

	This method is an escape hatch for when the Roact element creation and
	reconciliation algorithms are not fast enough for specific cases. Poorly
	written shouldUpdate methods *will* cause hard-to-trace bugs.

	If you're thinking of writing a shouldComponent function, consider using
	PureComponent instead, which provides a good implementation.

	This function must be faster than the render method in order to be a
	performance improvement.
]]
function Component:shouldUpdate(newProps, newState)
	return true
end

--[[
	Applies new state to the component. `partialState` is merged into the
	current state object.
]]
function Component:setState(partialState)
	-- If setState was disabled, we should check for a detailed message and
	-- display it.
	if self._setStateBlockedReason ~= nil then
		local messageSource = invalidSetStateMessages[self._setStateBlockedReason]

		if messageSource == nil then
			messageSource = invalidSetStateMessages["default"]
		end

		-- We assume that each message has a formatting placeholder for a component name.
		local formattedMessage = string.format(messageSource, tostring(getmetatable(self)))

		error(formattedMessage, 2)
	end

	-- If the partial state is a function, invoke it to get the actual partial state.
	if type(partialState) == "function" then
		partialState = partialState(self.state, self.props)

		-- If partialState is nil, abort the render.
		if partialState == nil then
			return
		end
	end

	local newState = mergeState(self.state, partialState)
	self:_update(self.props, newState)
end

--[[
	Notifies the component that new props and state are available.

	If shouldUpdate returns true, this method will trigger a re-render and
	reconciliation step.
]]
function Component:_update(newProps, newState)
	self._setStateBlockedReason = "shouldUpdate"
	local doUpdate = self:shouldUpdate(newProps or self.props, newState or self.state)
	self._setStateBlockedReason = nil

	if doUpdate then
		self:_forceUpdate(newProps, newState)
	end
end

--[[
	Forces the component to re-render itself and its children.

	newProps and newState are optional.
]]
function Component:_forceUpdate(newProps, newState)
	-- Compute new derived state.
	-- Get the class - getDerivedStateFromProps is static.
	local class = getmetatable(self)

	-- Only update if newProps are given!
	if newProps then
		if class.getDerivedStateFromProps then
			local derivedState = class.getDerivedStateFromProps(newProps, newState or self.state)

			-- getDerivedStateFromProps can return nil if no changes are necessary.
			if derivedState ~= nil then
				newState = mergeState(newState or self.state, derivedState)
			end
		end
	end

	if self.willUpdate then
		self._setStateBlockedReason = "willUpdate"
		self:willUpdate(newProps or self.props, newState or self.state)
		self._setStateBlockedReason = nil
	end

	local oldProps = self.props
	local oldState = self.state

	if newProps then
		self.props = newProps
	end

	if newState then
		self.state = newState
	end

	self._setStateBlockedReason = "render"
	local newChildElement = self:render()
	self._setStateBlockedReason = nil

	self._setStateBlockedReason = "reconcile"
	if self._handle._reified ~= nil then
		-- We returned an element before, update it.
		self._handle._reified = Reconciler._reconcileInternal(
			self._handle._reified,
			newChildElement
		)
	elseif newChildElement then
		-- We returned nil last time, but not now, so construct a new tree.
		self._handle._reified = Reconciler._reifyInternal(
			newChildElement,
			self._handle._parent,
			self._handle._key,
			self._context
		)
	end
	self._setStateBlockedReason = nil

	if self.didUpdate then
		self:didUpdate(oldProps, oldState)
	end
end

--[[
	Initializes the component instance and attaches it to the given
	instance handle, created by Reconciler._reify.
]]
function Component:_reify(handle)
	self._handle = handle

	self._setStateBlockedReason = "render"
	local virtualTree = self:render()
	self._setStateBlockedReason = nil

	if virtualTree then
		self._setStateBlockedReason = "reconcile"
		handle._reified = Reconciler._reifyInternal(
			virtualTree,
			handle._parent,
			handle._key,
			self._context
		)
		self._setStateBlockedReason = nil
	end

	if self.didMount then
		self:didMount()
	end
end

--[[
	Destructs the component and invokes all necessary lifecycle methods.
]]
function Component:_teardown()
	local handle = self._handle

	if self.willUnmount then
		self._setStateBlockedReason = "willUnmount"
		self:willUnmount()
		self._setStateBlockedReason = nil
	end

	-- Stateful components can return nil from render()
	if handle._reified then
		Reconciler.teardown(handle._reified)
	end

	self._handle = nil
end

return Component
