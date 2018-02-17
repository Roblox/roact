--[[
	The base component implementation that is extended by users of Roact.

	Exposed as Roact.Component
]]

local Reconciler = require(script.Parent.Reconciler)

local Component = {}

Component.__index = Component

-- The error message that is thrown when setState is called in the wrong place.
-- This is declared here to avoid really messy indentation.
local INVALID_SETSTATE_MESSAGE = [[
setState cannot be used currently, are you calling setState from any of:
* the willUpdate or willUnmount lifecycle hooks
* the init function
* the render function
* the shouldUpdate function]]

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

		self.props = props
		-- Used for tracking whether the component is in a position to set state.
		self._canSetState = false
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
			class.init(self, props)
		end

		-- The user constructer might not set state, so we can.
		if not self.state then
			self.state = {}
		end

		-- Now that state has definitely been set, we can now allow it to be changed.
		self._canSetState = true

		return self
	end

	return class
end

--[[
	Override this with a function that returns the elements that should
	represent this component with the current state.
]]
function Component:render()
	error("`render` must be defined when creating a Roact class!")
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
	-- State cannot be set in any lifecycle hooks.
	if not self._canSetState then
		error(INVALID_SETSTATE_MESSAGE, 0)
	end

	local newState = {}

	for key, value in pairs(self.state) do
		newState[key] = value
	end

	for key, value in pairs(partialState) do
		newState[key] = value
	end

	self:_update(self.props, newState)
end

--[[
	Notifies the component that new props and state are available.

	If shouldUpdate returns true, this method will trigger a re-render and
	reconciliation step.
]]
function Component:_update(newProps, newState)
	self._canSetState = false
	local willUpdate = self:shouldUpdate(newProps or self.props, newState or self.state)
	self._canSetState = true

	if willUpdate then
		self:_forceUpdate(newProps, newState)
	end
end

--[[
	Forces the component to re-render itself and its children.

	newProps and newState are optional.
]]
function Component:_forceUpdate(newProps, newState)
	self._canSetState = false
	if self.willUpdate then
		self:willUpdate(newProps or self.props, newState or self.state)
	end

	local oldProps = self.props
	local oldState = self.state

	if newProps then
		self.props = newProps
	end

	if newState then
		self.state = newState
	end

	local newChildElement = self:render()

	if self._handle._reified ~= nil then
		-- We returned an element before, update it.
		self._handle._reified = Reconciler._reconcile(
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

	self._canSetState = true

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

	local vdom = self:render()
	if vdom then
		handle._reified = Reconciler._reifyInternal(
			vdom,
			handle._parent,
			handle._key,
			self._context
		)
	end

	if self.didMount then
		self:didMount()
	end
end

return Component
