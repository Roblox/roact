return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	local function ClockApp(props)
		local time = props.time

		return Roact.createElement("ScreenGui", nil, {
			Main = Roact.createElement("TextLabel", {
				Size = UDim2.new(0, 400, 0, 300),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Text = "The current time is: " .. time,
			}),
		})
	end

	local running = true
	local currentTime = 0
	local handle = Roact.mount(Roact.createElement(ClockApp, {
		time = currentTime,
	}), PlayerGui)

	spawn(function()
		while running do
			currentTime = currentTime + 1

			handle = Roact.reconcile(handle, Roact.createElement(ClockApp, {
				time = currentTime,
			}))

			wait(1)
		end
	end)

	local function stop()
		running = false
		Roact.unmount(handle)
	end

	return stop
end