--[[
	These messages are used by Component to help users diagnose when they're
	calling setState in inappropriate places.

	The indentation may seem odd, but it's necessary to avoid introducing extra
	whitespace into the error messages themselves.
]]

local invalidSetStateMessages = {}

invalidSetStateMessages["willUpdate"] = [[
setState cannot be used in the willUpdate lifecycle method.
Consider using the didUpdate method instead, or using getDerivedStateFromProps.

Check the definition of willUpdate in the component %q.]]

invalidSetStateMessages["willUnmount"] = [[
setState cannot be used in the willUnmount lifecycle method.
A component that is being unmounted cannot be updated!

Check the definition of willUnmount in the component %q.]]

invalidSetStateMessages["shouldUpdate"] = [[
setState cannot be used in the shouldUpdate lifecycle method.
shouldUpdate must be a pure function that only depends on props and state.

Check the definition of shouldUpdate in the component %q.]]

invalidSetStateMessages["init"] = [[
setState cannot be used in the init method.
During init, the component hasn't initialized yet, and isn't ready to render.

Instead, set the `state` value directly:

	self.state = {
		value = "foo"
	}

Check the definition of init in the component %q.]]

invalidSetStateMessages["render"] = [[
setState cannot be used in the render method.
render must be a pure function that only depends on props and state.

Check the definition of render in the component %q.]]

invalidSetStateMessages["reconcile"] = [[
setState cannot be called while a component is being reified or reconciled.
This is the step where Roact constructs Roblox instances, and starting another
render here would introduce bugs.

Check the component %q to see if setState is being called by:
* a child Ref
* a child Changed event
* a child's render method]]

invalidSetStateMessages["default"] = [[
setState can not be used in the current situation, but Roact couldn't find a
message to display.

This is a bug in Roact.
It was triggered by the component %q.
]]

return invalidSetStateMessages