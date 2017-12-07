# Props and State

## Props
Every Roact component instance has an associated set of props given to it. You specify these when you're creaing an element:

```lua
Roact.createElement("Frame", {
	BackgroundColor3 = Color3.new(1, 0, 0),
	-- Your 'props' go here!
})
```

In the case of primitive elements, these props (mostly) turn directly into the values attached to the Roblox instance.

## State
State is attached to *stateful* Roact component instances. From inside a stateful component, you can read it with `self.state`, and write to it using `self:setState`:

```lua
local MyComponent = Roact.Component:extend("MyComponent")

function MyComponent:init()
	-- The only time you should ever assign to self.state directly is in your constructor.
	self.state = {
		value = 1,
	}
end

function MyComponent:render()
	return Roact.createElement("Frame", {
		BackgroundColor3 = Color3.new(self.state.value, 0, 0)
	})
end
```