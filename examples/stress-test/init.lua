return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	local App = require(script.App)

	local app = Roact.createElement("ScreenGui", nil, {
		Main = Roact.createElement(App),
	})

	local handle = Roact.mount(app, PlayerGui)

	local function stop()
		Roact.unmount(handle)
	end

	return stop
end