local Roact = require(game.ReplicatedStorage.Roact)

local e = Roact.createElement

local function body()
	return e("ScreenGui", nil, {
		A = e("TextLabel", {
			Text = "A",
		}, {
			B = e("TextLabel", {
				Text = "B",
			}),

			C = e("TextLabel", {
				Text = "C",
			}, {
				D = e("TextLabel", {
					Text = "D",
				}),

				E = e("TextLabel", {
					Text = "E",
				}),
			}),
		}),
	})
end

local tree = Roact.mount(body(), game.Players.LocalPlayer.PlayerGui, "Roact Root")