return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	local app = Roact.createElement("ScreenGui", nil, {
		Button = Roact.createElement("TextButton", {
			Size = UDim2.new(0.5, 0, 0.5, 0),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),

			-- Attach event listeners using `Roact.Event[eventName]`
			-- Event listeners get `rbx` as their first parameter
			-- followed by their normal event arguments.
			[Roact.Event.Activated] = function(_rbx)
				print("The button was clicked!")
			end,
		}),
	})

	local handle = Roact.mount(app, PlayerGui)

	local function stop()
		Roact.unmount(handle)
	end

	return stop
end
