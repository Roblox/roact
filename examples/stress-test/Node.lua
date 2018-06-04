local Roact = require(game.ReplicatedStorage.Roact)

local Constants = require(script.Parent.Constants)

local function Node(props)
	local x = props.x
	local y = props.y
	local time = props.time

	local n = time + x / Constants.NODE_SIZE + y / Constants.NODE_SIZE

	return Roact.createElement("Frame", {
		Size = UDim2.new(0, Constants.NODE_SIZE, 0, Constants.NODE_SIZE),
		Position = UDim2.new(0, Constants.NODE_SIZE * x, 0, Constants.NODE_SIZE * y),
		BackgroundColor3 = Color3.new(0.5 + 0.5 * math.sin(n), 0.5, 0.5),
	})
end

return Node