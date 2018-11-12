*Refs* grant access to the Roblox Instance objects that are created by Roact. They're an escape hatch for when something is difficult or impossible to correctly express with the Roact API.

Refs are intended to be used in cases where Roact cannot solve a problem directly, or its solution might not be performant enough, like:

* Resizing a box to fit its contents dynamically
* Gamepad selection
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

## Refs in Roblox
Certain classes of Roblox Instance have properties that can only be set to other Roblox Instances. This makes it difficult to do something like this:
```lua
local function Buttons(props)
	return Roact.createElement("Frame", {
		LeftButton = Roact.createElement("TextButton", {
			Text = "Foo",
			-- This field expects a Roblox Instance
			NextSelectionRight = nil, -- What goes here?
		}),
		RightButton = Roact.createElement("TextButton", {
			Text = "Bar",			
			-- This field expects a Roblox Instance
			NextSelectionLeft = nil, -- What goes here?
		})
	})
end
```

In Roact, we don't deal directly with Roblox Instances. In order to provide valid values to fields like `NextSelectionRight`, Roact has a special rule in the reconciler that allows us to use object refs (not function refs) in place of the Roblox Instances that they represent.

We can implement the above example like this:
```lua
function Buttons:init()
	self.leftButtonRef = Roact.createRef()
	self.rightButtonRef = Roact.createRef()
end

function Buttons:render()
	return Roact.createElement("Frame", {
		LeftButton = Roact.createElement("TextButton", {
			[Roact.Ref] = self.leftButtonRef,

			Text = "Foo",
			NextSelectionRight = self.rightButtonRef,
		}),
		RightButton = Roact.createElement("TextButton", {
			[Roact.Ref] = self.rightButtonRef,

			Text = "Bar",			
			NextSelectionLeft = self.leftButtonRef,
		})
	})
end
```
Now, Roact assigns the Instances referred to by `self.leftButtonRef` and `self.rightButtonRef` to the properties `NextSelectionRight` and `NextSelectionLeft`. Under the hood, these properties will update any time the ref itself updates, which means that *we don't need to worry about the order in which the properties are assigned*.

!!! warning
	This pattern does *not* work with function refs. Function refs have no way of tracking the underlying Instance with which they are associated. Additionally, function refs are indistinguishable from functions; it isn't safe to assume that they should be substituted for Instances.