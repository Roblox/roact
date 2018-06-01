local Roact = require(game.ReplicatedStorage.Roact)

local function body(text)
	return Roact.createElement("ScreenGui", nil, {
		Label = text == "Hello, world!" and Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Text = text,
		}) or nil,
	})
end

local tree = Roact.mount(body("Hello, world!"), game.Players.LocalPlayer.PlayerGui)

wait(0.7)

Roact.reconcileTree(tree, body("Hello, world!"), body("Hey!"))