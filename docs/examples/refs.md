# Refs
*Refs* are a concept that let you break out of the Roact paradigm and access Roblox instances directly.

Pass a function as a prop using the key `Roact.Ref` to receive the reference.

When the object being referenced is destroyed, the given Ref function will be passed nil. Use this opportunity to forget what you were given.

If the Ref object changes, or the instance that the Ref is tied to gets replaced, the old Ref will be passed `nil`, and the new Ref will be passed the current object reference.

This feature is intended to be an *escape hatch* -- it shouldn't be necessary for the majority of work using Roact. If you do find yourself using a Ref, there may be a Roact paradigm that fits your needs better. Otherwise, you should encapsulate your usage of Ref into a component and expose a cleaner API from it.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Roact)

local currentFrame

local element = Roact.createElement("Frame", {
	-- Use Roact.Ref as the key to attach a ref, just like events.
	[Roact.Ref] = function(rbx)
		-- All properties are already set and the object has been parented at this point.
		currentFrame = rbx
	end
})

-- We'll put our frame into nil, since the parent doesn't matter
local instance = Roact.reify(element, nil, "SomeName")

print("currentFrame is", currentFrame)

-- Tear down the tree we created
Roact.teardown(instance)

print("currentFrame is now", currentFrame)
```