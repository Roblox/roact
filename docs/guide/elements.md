Like React, everything in Roact is built out of elements. Elements are the smallest building blocks for creating UI.

Elements describe what you want your UI to look like at a single point in time. They're [immutable](https://en.wikipedia.org/wiki/Immutable_object): you can't change elements once they're created, but you can create new ones. Because creating elements is fast, this is no big deal.

You can create an element using `Roact.createElement`. You will need to pass it a Roblox class name as the first argument (this is a kind of component, which we discuss in the [next section](../components)), and any properties as the second argument!

```lua
local myElement = Roact.createElement("Frame", {
	Size = UDim2.new(0, 50, 0, 50)
})
```

You can also represent children by passing them to the optional third argument of `createElement`:

```lua
local myElement = Roact.createElement("Frame", {
	Size = UDim2.new(0, 50, 0, 50)
}, {
	SomeChild = Roact.createElement("TextLabel", {
		Text = "Hello, Roact!"
	})
})
```

Creating an element by itself doesn't do anything, however. In order to turn our description of an object into a real Roblox Instance, we can call `Roact.mount`:

```lua
-- Create a new Frame object in 'Workspace'
local myHandle = Roact.mount(myElement, game.Workspace)
```

Mounting is the process of creating a Roact component instance as well as any associated Roblox Instances.

`Roact.mount` returns a handle that we can later use to update or destroy that object with `Roact.update` and `Roact.unmount`.

## Changing What's Rendered
In order to change the UI that we've created, we need to create a new set of elements and *update* the existing tree to match it.

Reconciliation is the term that Roact uses to describe the process of updating an existing UI to match what the program wants it to look like at any given time.

Using `myHandle` from above, we can update the size and text of our label:

```lua
-- Make some new elements that describe what our new UI will look like.
local myNewElement = Roact.createElement("Frame", {
	Size = UDim2.new(0, 100, 0, 50)
}, {
	SomeChild = Roact.createElement("TextLabel", {
		Text = "Hello, again, Roact!"
	})
})

-- Update our hierarchy to match those elements.
myHandle = Roact.update(myHandle, myNewElement)
```

!!! info
	Most projects using UI don't use `Roact.update` and instead change UI using state and lifecycle events, which will be introduced in the next section.

	`Roact.update` is mostly useful to embed Roact components into existing, non-Roact projects, and for introducing Roact!

Unlike many other UI systems, Roact doesn't let you directly set values on UI objects. Instead, describe what your UI should look like in the form of elements and Roact will handle changing the underlying Roblox Instances.

## Unmounting the Tree
Roact provides a method called `Roact.unmount` that we can use when we're finished with our tree.

```lua
Roact.unmount(myHandle)
```

Unmounting destructs the given Roact component instance and destroys any associated Roblox Instances with it.

!!! warning
	Trying to use a handle after it's been passed to `Roact.unmount` will result in errors!

## Incrementing Counter
Using what's been covered so far, we can make a simple program that tells you how long it has been running.

This is a complete example that should work when put into a `LocalScript` in `StarterPlayerScripts`. It assumes Roact has been installed into `ReplicatedStorage`.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Roact)

-- Create a function that creates the elements for our UI.
-- Later, we'll use components, which are the best way to organize UI in Roact.
local function clock(currentTime)
	return Roact.createElement("ScreenGui", {}, {
		TimeLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Text = "Time Elapsed: " .. currentTime
		})
	})
end

local PlayerGui = Players.LocalPlayer.PlayerGui

-- Create our initial UI.
local currentTime = 0
local handle = Roact.mount(clock(currentTime), PlayerGui, "Clock UI")

-- Every second, update the UI to show our new time.
while true do
	wait(1)

	currentTime = currentTime + 1
	handle = Roact.update(handle, clock(currentTime))
end
```

In the next section, we'll talk about components, which let us create reusable chunks of UI, and introduce the primary technique to change UI in Roact.