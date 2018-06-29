local Roact = require(game.ReplicatedStorage.Roact)

local e = Roact.createElement

local function body()
	return e("ScreenGui", nil, {
		A = e("TextLabel", {
			Text = "A",
			Size = UDim2.new(0, 100, 0, 100),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			B = e("TextLabel", {
				Text = "B",
				Size = UDim2.new(0, 50, 0, 50),
				Position = UDim2.new(0, 0, 1, 0),
				AnchorPoint = Vector2.new(1, 0),
			}),

			C = e("TextLabel", {
				Text = "C",
				Size = UDim2.new(0, 50, 0, 50),
				Position = UDim2.new(1, 0, 1, 0),
				AnchorPoint = Vector2.new(0, 0),
			}, {
				D = e("TextLabel", {
					Text = "D",
					Size = UDim2.new(0, 25, 0, 25),
					Position = UDim2.new(0, 0, 1, 0),
					AnchorPoint = Vector2.new(1, 0),
				}),

				E = e("TextLabel", {
					Text = "E",
					Size = UDim2.new(0, 25, 0, 25),
					Position = UDim2.new(1, 0, 1, 0),
					AnchorPoint = Vector2.new(0, 0),
				}),
			}),
		}),
	})
end

local tree = Roact.mount(body(), game.Players.LocalPlayer.PlayerGui, "Roact Root")