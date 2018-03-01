# Elements
Like React, everything in Roact is built out of elements. Elements are the smallest building block for creating UI.

Elements describe what you want your UI to look like at a single point in time. They're [immutable](https://en.wikipedia.org/wiki/Immutable_object): you can't change elements once they're created, but you can create new ones.

You can create an element using `Roact.createElement` -- just pass a Roblox class name as the first argument, and any properties as the second argument!

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
	SomeChild = Roact.createElement("ImageLabel", {
		Image = "rbxassetid://5891234"
	})
})
```

Creating an element by itself doesn't do anything, however. In order to turn our description of an object into a real Roblox object, we can call `Roact.reify`:

```lua
-- Create a new Frame object in 'Workspace'
local myHandle = Roact.reify(myElement, game.Workspace)
```

`Roact.reify` returns a handle that you can later use to destroy that object with `Roact.teardown`:

```lua
Roact.teardown(myHandle)
```

In the next section, we'll talk about components, which let us create reusable chunks of UI, as well as *change* our existing UI without destroying it!