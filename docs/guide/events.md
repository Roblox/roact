# Events
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