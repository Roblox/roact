Roact manages Instance event connections automatically as part of rendering.

To connect to an event, pass a prop with `Roact.Event.EVENT_NAME` as the key and a function as the value.

Roact will pass the instance that the event is connected to as the first argument to the event callback, followed by any arguments that Roblox passed in.

```lua
local button = Roact.createElement("TextButton", {
	Text = "Click me!",
	Size = UDim2.new(0, 400, 0, 300),

	[Roact.Event.MouseButton1Click] = function(rbx)
		print("The button was clicked!")
	end
})
```

!!! info
	Events will automatically be disconnected when a component instance is unmounted!

To listen to `GetPropertyChangedSignal`, Roact provides a similar API, using props like `Roact.Change.PROPERTY_NAME`:

```lua
local frame = Roact.createElement("Frame", {
	[Roact.Change.AbsoluteSize] = function(rbx)
		print("Absolute size changed to", rbx.AbsoluteSize)
	end
})
```

!!! warning
	Roact can trigger events while updating the tree! If Roact triggers an event handler that calls `setState` synchronously, an error will be thrown. In the future, Roact may delay evaluation of event handlers to prevent them from happening while Roact is modifying the tree.