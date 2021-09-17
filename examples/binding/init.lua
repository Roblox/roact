return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	local BindingExample = Roact.Component:extend("BindingExample")

	function BindingExample:init()
		self.binding, self.updateBinding = Roact.createBinding(0)
	end

	function BindingExample:render()
		return Roact.createElement("Frame", {
			Size = UDim2.new(0, 200, 0, 200),
			Position = self.binding:map(function(value)
				return UDim2.new(0.5 + value / 200, 0, 0.5, 0)
			end),
			AnchorPoint = Vector2.new(0.5, 0.5),
			BorderSizePixel = self.binding,
		})
	end

	function BindingExample:didMount()
		self.running = true

		spawn(function()
			while self.running do
				-- With each update, the frame's border grows and it moves to the right
				self.updateBinding(self.binding:getValue() + 1)

				wait(0.1)
			end
		end)
	end

	function BindingExample:willUnmount()
		self.running = false
	end

	local app = Roact.createElement("ScreenGui", nil, {
		BindingExample = Roact.createElement(BindingExample),
	})

	local handle = Roact.mount(app, PlayerGui)

	local function stop()
		Roact.unmount(handle)
	end

	return stop
end
