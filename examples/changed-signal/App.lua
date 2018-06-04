--[[
	Displays a TextBox and a TextLabel that reverses the TextBox's input text
]]
local Roact = require(game.ReplicatedStorage.Roact)

local InputTextBox = require(script.Parent.InputTextBox)
local ReversedText = require(script.Parent.ReversedText)

local App = Roact.Component:extend("App")

function App:init()
	self.state = {
		text = ""
	}
end

function App:render()
	local text = self.state.text

	return Roact.createElement("Frame",{
			Size = UDim2.new(0, 400, 0, 400),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
	}, {
		Layout = Roact.createElement("UIListLayout", {
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		InputTextBox = Roact.createElement(InputTextBox, {
			layoutOrder = 1,
			onTextChanged = function(rbx)
				self:setState({
					text = rbx.Text or "",
				})
			end
		}),
		ReversedText = Roact.createElement(ReversedText, {
			layoutOrder = 2,
			inputText = text,
		})
	})
end

return App