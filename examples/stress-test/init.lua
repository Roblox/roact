return function()
	local RunService = game:GetService("RunService")
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	local NODE_SIZE = 10
	local GRID_SIZE = 50

	--[[
		A frame that changes its background color according to time and position props
	]]
	local function Node(props)
		local x = props.x
		local y = props.y
		local time = props.time

		local n = time + x / NODE_SIZE + y / NODE_SIZE

		return Roact.createElement("Frame", {
			Size = UDim2.new(0, NODE_SIZE, 0, NODE_SIZE),
			Position = UDim2.new(0, NODE_SIZE * x, 0, NODE_SIZE * y),
			BackgroundColor3 = Color3.new(0.5 + 0.5 * math.sin(n), 0.5, 0.5),
		})
	end

	--[[
		Displays a large number of nodes and updates each of them every RunService step
	]]
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
		for x = 0, GRID_SIZE - 1 do
			for y = 0, GRID_SIZE - 1 do
				n = n + 1
				nodes[n] = Roact.createElement(Node, {
					x = x,
					y = y,
					time = time,
				})
			end
		end

		return Roact.createElement("Frame", {
			Size = UDim2.new(0, GRID_SIZE * NODE_SIZE, 0, GRID_SIZE * NODE_SIZE),
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

	local app = Roact.createElement("ScreenGui", nil, {
		Main = Roact.createElement(App),
	})

	local handle = Roact.mount(app, PlayerGui)

	local function stop()
		Roact.unmount(handle)
	end

	return stop
end