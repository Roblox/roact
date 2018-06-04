local RunService = game:GetService("RunService")

local Roact = require(game.ReplicatedStorage.Roact)

local Node = require(script.Parent.Node)
local Constants = require(script.Parent.Constants)

local App = Roact.Component:extend("App")

function App:init()
	self.state = {
		time = tick(),
	}
end

function App:render()
	local time = self.state.time
	local nodes = {}

	local n = 0
	for x = 0, Constants.GRID_SIZE - 1 do
		for y = 0, Constants.GRID_SIZE - 1 do
			n = n + 1
			nodes[n] = Roact.createElement(Node, {
				x = x,
				y = y,
				time = time,
			})
		end
	end

	return Roact.createElement("Frame", {
		Size = UDim2.new(
			0, Constants.GRID_SIZE * Constants.NODE_SIZE,
			0, Constants.GRID_SIZE * Constants.NODE_SIZE
		),
		Position = UDim2.new(0.5, 0, 0.5, 0),
		AnchorPoint = Vector2.new(0.5, 0.5),
	}, nodes)
end

function App:didMount()
	self.connection = RunService.Stepped:Connect(function()
		self:setState({
			time = tick(),
		})
	end)
end

function App:willUnmount()
	self.connection:Disconnect()
end

return App