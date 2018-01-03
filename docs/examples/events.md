# Events, the Roact Way
Roact lets you declaratively attach and detach from events without worrying about cleanup.

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Roact)

local App = Roact.Component:extend("App")

function App:render()
	return Roact.createElement("ScreenGui", {
	}, {
		Button = Roact.createElement("TextButton", {
			Size = UDim2.new(0.5, 0, 0.5, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),

			-- Attach event listeners using `Roact.Event[eventName]`
			-- Event listeners get `rbx` as their first parameter.
			-- This is followed by their normal event arguments.
			[Roact.Event.MouseButton1Click] = function(rbx)
				print("The button", rbx, "was clicked!")
			end
		}),
	})
end

local element = Roact.createElement(App)

Roact.reify(element, Players.LocalPlayer.PlayerGui, "EventsExample")
```
