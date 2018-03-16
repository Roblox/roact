# Refs
*Refs* grant access to the actual Instance objects that are created by Roact. They're an escape hatch for when something is difficult or impossible to correctly express with the Roact API.

To create a ref, pass a function prop with the key `Roact.Ref` when creating a primitive element:

```lua
local frame = Roact.createElement("Frame", {
	[Roact.Ref] = function(rbx)
		print("Ref was called with", rbx, "of type", typeof(rbx))
	end
})

local handle = Roact.reify(frame)

-- Output:
--     Ref was called with Frame of type Instance

Roact.teardown(handle)

-- In the output:
--     Ref was called with nil of type nil
```

!!! info
	Refs can only be used with primitive components.

!!! warning
	When a component instance is destroyed or the ref property changes, `nil` will be passed to the old ref function!

**TODO: Continue!**