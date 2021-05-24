!!! info
	These examples assumes that you've successfully [installed Roact](installation.md) into `ReplicatedStorage`!

Add a new `LocalScript` object to `StarterPlayer.StarterPlayerScripts` either in Roblox Studio, or via Rojo:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Roact)

local app = Roact.createElement("ScreenGui", {}, {
	HelloWorld = Roact.createElement("TextLabel", {
		Size = UDim2.new(0, 400, 0, 300),
		Text = "Hello, Roact!"
	})
})

Roact.mount(app, Players.LocalPlayer.PlayerGui)
```

When you run your game, you should see a large gray label with the phrase 'Hello, Roact!' appear on screen!
