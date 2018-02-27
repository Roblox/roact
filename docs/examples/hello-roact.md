# Hello, Roact!
This sample creates a full-screen `TextLabel` with a greeting:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Roact)

-- Define a functional component
local function HelloComponent()
	--[[
		createElement takes three arguments:
			* The component that this element represents
			* Optional: a list of properties to provide
			* Optional: a dictionary of children -- the key is that child's Name
	]]

	return Roact.createElement("ScreenGui", {
	}, {
		MainLabel = Roact.createElement("TextLabel", {
			Text = "Hello, world!",
			Size = UDim2.new(1, 0, 1, 0),
		}),
	})
end

-- Create our virtual tree
local element = Roact.createElement(HelloComponent)

--[[
	`reify` turns our virtual tree into real instances and puts the top-most one
	in PlayerGui

	reify takes three arguments:
		* The element we're trying to reify
		* Optionally, the Roblox Instance to put the result into
		* Optionally, what to name the root element we create
]]
Roact.reify(element, Players.LocalPlayer.PlayerGui, "HelloWorld")
```

We can also write this example using a *stateful* component.

This example behaves exactly the same as the functional one above:

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Roact)

-- Create a component type, just like the functional component above
local HelloComponent = Roact.Component:extend("HelloComponent")

-- 'render' MUST be overridden.
function HelloComponent:render()
	return Roact.createElement("ScreenGui", {
	}, {
		MainLabel = Roact.createElement("TextLabel", {
			Text = "Hello, world!",
			Size = UDim2.new(1, 0, 1, 0),
		}),
	})
end

-- Create our virtual tree
local element = Roact.createElement(HelloComponent)

-- Turn our virtual tree into real instances and put them in PlayerGui
Roact.reify(element, Players.LocalPlayer.PlayerGui, "HelloWorld")
```