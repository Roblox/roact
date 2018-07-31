*Refs* grant access to the Roblox Instance objects that are created by Roact. They're an escape hatch for when something is difficult or impossible to correctly express with the Roact API.

Refs are intended to be used in cases where Roact cannot solve a problem directly, or its solution might not be performant enough, like:

* Resizing a box to fit its contents dynamically
* Handling gamepad selection
* Animations

Refs can only be attached to primitive components. This is different than React, where refs can be used to call members of composite components.

## Refs in Action
To use a ref, call `Roact.createRef()` and put the result somewhere persistent. Generally, that means that refs are only used inside stateful components.

```lua
local Foo = Roact.Component:extend("Foo")

function Foo:init()
	self.textBoxRef = Roact.createRef()
end
```

Next, use the ref inside of `render` by creating a primitive component. Refs use the special key `Roact.Ref`.

```lua
function Foo:render()
	return Roact.createElement("TextBox", {
		[Roact.Ref] = self.textBoxRef,
	})
end
```

Finally, we can use the value of the ref at any point after our component is mounted.

```lua
function Foo:didMount()
	-- The actual Instance is stored in the 'current' property of a ref object.
	local textBox = self.textBoxRef.current

	print("TextBox has this text:", textBox.Text)
end
```

## Function Refs
The original ref API was based on functions instead of objects. Its use is not recommended for most cases anymore, but it can still be useful in some cases.

This style of ref involves passing a function as the `Roact.Ref` prop as opposed to a dedicated ref object:

```lua
local function Bar(props)
	return Roact.createElement("TextBox", {
		[Roact.Ref] = function(instance)
			-- Be careful to guard against nil refs; this is a gotcha of
			-- function refs.
			if instance ~= nil then
				print("TextBox has this text:", instance.Text)
			else
				print("TextBox ref removed.")
			end
		end,
	})
end
```

!!! warning
	When a function ref is called, it's not guaranteed that its sibling or parent components have finished mounting. Causing side effects here can cause difficult-to-trace bugs.

!!! warning
	When a component with a function ref unmounts, or when the ref value changes, the component's ref is passed `nil`.