# Getting Started
There are two supported ways to get started with Roact.

## Installation
For our examples, we'll install `Roact` to `ReplicatedStorage`. In practice, it's okay to install Roact anywhere you want!

### Method 1: Installation Script (Roblox Studio)
* Download the latest release from the [GitHub releases page](https://github.com/Roblox/Roact/releases).
* Use the 'Run Script' menu (located in the Test tab) to locate and run this script.
* Follow the installer's instructions to put Roact into `ReplicatedStorage`

### Method 2: Rojo
* Install [Rojo](https://github.com/LPGhatguy/rojo), a file sync plugin
* Put Roact into your project:
	* Copy the `lib` folder into your project, and rename it to `Roact`
	* Alternatively, add a Git submodule to your project
* Add a partition in Rojo to put Roact into `ReplicatedStorage.Roact`

## Hello, World!
At this point, Roact should be located inside `ReplicatedStorage`!

Add a new `LocalScript` to `StarterPlayer.StarterPlayerScripts` either in Roblox Studio, or via Rojo:

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

Roact.reify(app, Players.LocalPlayer.PlayerGui)
```

When you run your game, you should see a large gray label with the phrase 'Hello, Roact!' appear on screen!