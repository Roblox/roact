--[[
	The base implementation of a stateful component in Roact.

	Stateful components handle most of their own mounting and reconciliation
	process. Many of the private methods here are invoked by the reconciler.

	Stateful components expose a handful of lifecycle events:
	- didMount
	- willUnmount
	- willUpdate
	- didUpdate
	- (static) getDerivedStateFromProps

	These lifecycle events line up with their semantics in React, and more
	information (and a diagram) is available in the Roact documentation.
]]

local Reconciler = require(script.Parent.Reconciler)
local Core = require(script.Parent.Core)
local GlobalConfig = require(script.Parent.GlobalConfig)
local Instrumentation = require(script.Parent.Instrumentation)
local Heapstack = require(script.Parent.Heapstack)

local invalidSetStateMessages = require(script.Parent.invalidSetStateMessages)

local Component = {}

-- Locally cache tick so we can minimize impact of calling it for instrumentation
local tick = tick

Component.__index = Component

--[[
	Merge any number of dictionaries into a new dictionary, overwriting keys.

	If a value of `Core.None` is encountered, the key will be removed instead.
	This is necessary because Lua doesn't differentiate between a key being
	missing and a key being set to nil.
]]
local function merge(...)
	local result = {}

	for i = 1, select("#", ...) do
		local entry = select(i, ...)

		for key, value in pairs(entry) do
			if value == Core.None then
				result[key] = nil
			else
				result[key] = value
			end
		end
	end

	return result
end

local function setLock(component, value)
	component._setStateBlockedReason = value
end

local function initState(component, class, props)
	-- The user constructer might not set state, so we can.
	if not component.state then
		component.state = {}
	end

	if class.getDerivedStateFromProps then
		local partialState = class.getDerivedStateFromProps(props, component.state)

		if partialState then
			component.state = merge(component.state, partialState)
		end
	end
end

local function updateDerivedState(getDerivedStateFromProps, newValues)
	local derivedState = getDerivedStateFromProps(newValues.newProps, newValues.newState)

	-- getDerivedStateFromProps can return nil if no changes are necessary.
	if derivedState ~= nil then
		newValues.newState = merge(newValues.newState, derivedState)
	end
end

local function updateDefaultProps(defaultProps, newValues)
	-- We only allocate another prop table if there are props that are
	-- falling back to their default.
	for key in pairs(defaultProps) do
		if newValues.newProps[key] == nil then
			newValues.newProps = merge(defaultProps, newValues.newProps)
			return
		end
	end
end

local function callWillUpdate(component, newValues)
	component._setStateBlockedReason = "willUpdate"
	component:willUpdate(newValues.newProps, newValues.newState)
end

local function callRender(component, stack, newValues)
	if newValues then
		component.props = newValues.newProps
		component.state = newValues.newState
	end

	local handle = component._handle

	component._setStateBlockedReason = "render"
	local newChildElement
	if GlobalConfig.getValue("componentInstrumentation") then
		local startTime = tick()

		newChildElement = component:render()

		local elapsed = tick() - startTime
		Instrumentation.logRenderTime(handle, elapsed)
	else
		newChildElement = component:render()
	end

	-- Reconcilation doesn't take place unless render completed successfully. Otherwise we
	-- are doing work that we know is incorrect and we could get way without doing.
	if handle._child ~= nil then
		component._setStateBlockedReason = "reconcile"
		-- We returned an element during our last render, update it.
		stack:push(Reconciler._reconcileInternal, stack, handle, handle._child, newChildElement)
	elseif newChildElement then
		component._setStateBlockedReason = "reconcile"
		-- We returned nil during our last render, construct a new child.
		stack:push(Reconciler._mountInternal, stack, handle, newChildElement, handle._parent, handle._key, component._context)
	end
end
--[[
	Create a new stateful component.

	Not intended to be a general OO implementation, this function only intends
	to let users extend Component and PureComponent.

	Instead of using inheritance, use composition and props to extend
	components.
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

	function class._new(stack, handle, context)
		local self = {}
		handle._instance = self
		self._handle = handle

		local props = handle._element.props

		-- When set to a value, setState will fail, using the given reason to
		-- create a detailed error message.
		-- You can see a list of reasons in invalidSetStateMessages.
		self._setStateBlockedReason = nil

		if class.defaultProps == nil then
			self.props = props
		else
			self.props = merge(class.defaultProps, props)
		end

		self._context = {}

		-- Shallow copy all context values from our parent element.
		if context then
			for key, value in pairs(context) do
				self._context[key] = value
			end
		end

		setmetatable(self, class)

		if self.didMount then
			stack:push(self.didMount, self)
		end

		stack:push(setLock, self, nil)
		stack:push(callRender, self, stack)
		stack:push(initState, self, class, props)

		-- Call the user-provided initializer, where state and _props are set.
		if class.init then
			stack:push(setLock, self, nil)
			self._setStateBlockedReason = "init"
			class.init(self, props)
		end
	end

	return class
end

--[[
	render is intended to describe what a UI should look like at the current
	point in time.

	The default implementation throws an error, since forgetting to define
	render is usually a mistake.

	The simplest implementation for render is:

		function MyComponent:render()
			return nil
		end

	You should explicitly return nil from functions in Lua to avoid edge cases
	related to none versus nil.
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

	If you're thinking of writing a shouldUpdate function, consider using
	PureComponent instead, which provides a good implementation given that your
	data is immutable.

	This function must be faster than the render method in order to be a
	performance improvement.
]]
function Component:shouldUpdate(newProps, newState)
	return true
end

--[[
	Applies new state to the component.

	partialState may be one of two things:
	- A table, which will be merged onto the current state.
	- A function, returning a table to merge onto the current state.

	The table variant generally looks like:

		self:setState({
			foo = "bar",
		})

	The function variant generally looks like:

		self:setState(function(prevState, props)
			return {
				foo = prevState.count + 1,
			})
		end)

	The function variant may also return nil in the callback, which allows Roact
	to cancel updating state and abort the render.

	Future versions of Roact will potentially batch or delay state merging, so
	any state updates that depend on the current state should use the function
	variant.
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

	local newState = merge(self.state, partialState)

	local stack = Heapstack.new(true)
	stack:push(self._update, self, stack, nil, newState)
	stack:run()
end

--[[
	Returns the current stack trace for this component, or nil if the
	elementTracing configuration flag is set to false.
]]
function Component:getElementTraceback()
	return self._handle._element.source
end

--[[
	Notifies the component that new props and state are available. This function
	is invoked by the reconciler.

	If shouldUpdate returns true, this method will trigger a re-render and
	reconciliation step.
]]
function Component:_update(stack, newProps, newState)
	stack:push(self._forceUpdate, self, stack, newProps, newState)
	stack:push(setLock, self, nil)
	self._setStateBlockedReason = "shouldUpdate"

	local doUpdate

	if GlobalConfig.getValue("componentInstrumentation") then
		local startTime = tick()

		doUpdate = self:shouldUpdate(newProps or self.props, newState or self.state)

		local elapsed = tick() - startTime
		Instrumentation.logShouldUpdate(self._handle, doUpdate, elapsed)
	else
		doUpdate = self:shouldUpdate(newProps or self.props, newState or self.state)
	end

	if not doUpdate then
		self._setStateBlockedReason = nil
		stack:pop()
		-- Prevents _forceUpdate from running after this
		-- But if this code isn't reached because shouldUpdate threw,
		-- the component will still update.
		stack:pop()
	end
end

--[[
	Forces the component to re-render itself and its children.

	This is essentially the inner portion of _update.

	newProps and newState are optional.
]]
function Component:_forceUpdate(stack, newProps, newState)
	if self.didUpdate then
		stack:push(self.didUpdate, self, self.props, self.state)
	end

	local newValues = {
		newProps = newProps or self.props,
		newState = newState or self.state,
	}

	stack:push(setLock, self, nil)
	stack:push(callRender, self, stack, newValues)
	if self.willUpdate then
		stack:push(callWillUpdate, self, newValues)
	end
	-- If newProps are passed, compute derived state and default props
	if newProps then
		local class = getmetatable(self)
		if class.getDerivedStateFromProps then
			stack:push(updateDerivedState, class.getDerivedStateFromProps, newValues)
		end
		if class.defaultProps then
			stack:push(updateDefaultProps, class.defaultProps, newValues)
		end
	end
end

--[[
	Destructs the component and invokes all necessary lifecycle methods.
]]
function Component:_unmount(stack)
	self._handle = nil
	if self.willUnmount then
		stack:push(setLock, self, nil)
		self._setStateBlockedReason = "willUnmount"
		stack:push(self.willUnmount, self)
	end
end

return Component
