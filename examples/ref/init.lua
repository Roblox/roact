return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	local SearchBar = require(script.SearchBar)

	local app = Roact.createElement("ScreenGui", nil, {
		SearchBar = Roact.createElement(SearchBar),
	})

	local handle = Roact.mount(app, PlayerGui)

	local function stop()
		Roact.unmount(handle)
	end

	return stop
end