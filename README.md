> This repository is deprecated and no longer maintained.
> 
> See [react-lua](https://github.com/Roblox/react-lua) for our currently maintained React in Lua library.

<h1 align="center">Roact</h1>
<div align="center">
	<a href="https://github.com/Roblox/roact/actions"><img src="https://github.com/Roblox/roact/workflows/CI/badge.svg" alt="GitHub Actions Build Status" /></a>
	<a href="https://coveralls.io/github/Roblox/roact?branch=master"><img src="https://coveralls.io/repos/github/Roblox/roact/badge.svg?branch=master" alt="Coveralls Coverage" /></a>
	<a href="https://roblox.github.io/roact"><img src="https://img.shields.io/badge/docs-website-green.svg" alt="Documentation" /></a>
</div>

<div align="center">
	A declarative UI library for Roblox Lua inspired by <a href="https://reactjs.org">React</a>.
</div>

<div>&nbsp;</div>

## Installation

### Method 1: Model File (Roblox Studio)
* Download the `rbxm` model file attached to the latest release from the [GitHub releases page](https://github.com/Roblox/Roact/releases).
* Insert the model into Studio into a place like `ReplicatedStorage`

### Method 2: Filesystem
* Copy the `src` directory into your codebase
* Rename the folder to `Roact`
* Use a plugin like [Rojo](https://github.com/LPGhatguy/rojo) to sync the files into a place

## [Documentation](https://roblox.github.io/roact)
For a detailed guide and examples, check out [the official Roact documentation](https://roblox.github.io/roact).

```lua
local LocalPlayer = game:GetService("Players").LocalPlayer

local Roact = require(Roact)

-- Create our virtual tree describing a full-screen text label.
local tree = Roact.createElement("ScreenGui", {}, {
	Label = Roact.createElement("TextLabel", {
		Text = "Hello, world!",
		Size = UDim2.new(1, 0, 1, 0),
	}),
})

-- Turn our virtual tree into real instances and put them in PlayerGui
Roact.mount(tree, LocalPlayer.PlayerGui, "HelloWorld")
```

## License
Roact is available under the Apache 2.0 license. See [LICENSE.txt](LICENSE.txt) for details.