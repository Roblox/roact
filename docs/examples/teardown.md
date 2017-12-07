# Tearing Down Components
Roact components don't need to live forever. It would be pretty awful if they didn't clean up after themselves!

Thankfully, you can use `Roact.teardown` to destroy top-level Roact component instances. In a lot of apps, you don't need to do this, but if you're embedding Roact as part of a larger system, this is helpful.

**Do not tear down anything except a root node.** Roact will be very unhappy with you and probably crash if you do.

```lua
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Roact)

-- We're going to create a very large Part!
local element = Roact.createElement("Part", {
	Anchored = true,
	Size = Vector3.new(50, 50, 50),
})

-- Did you know that 'reify' returns a handle you can use?
local instance = Roact.reify(element, Workspace, "ObnoxiousPart")

-- We can observe that our part was created and stuffed into Workspace:
print("Here it is:", Workspace:FindFirstChild("ObnoxiousPart"))

-- And then we can destroy it and observe that it's gone!
Roact.teardown(instance)

print("...and it's gone:", Workspace:FindFirstChild("ObnoxiousPart"))
```