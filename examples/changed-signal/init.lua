return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	--[[
		A TextBox that the user can type into. Takes a callback to be
		triggered when text changes.
	]]
	local function InputTextBox(props)
		local onTextChanged = props.onTextChanged
		local layoutOrder = props.layoutOrder

		return Roact.createElement("TextBox", {
			LayoutOrder = layoutOrder,
			Text = "Type Here!",
			Size = UDim2.new(1, 0, 0.5, 0),
			[Roact.Change.Text] = onTextChanged,
		})
	end

	--[[
		A TextLabel that display the given text in reverse.
	]]
	local function ReversedText(props)
		local inputText = props.inputText
		local layoutOrder = props.layoutOrder

		return Roact.createElement("TextLabel", {
			LayoutOrder = layoutOrder,
			Size = UDim2.new(1, 0, 0.5, 0),
			Text = "Reversed: " .. inputText:reverse(),
		})
	end

	--[[
		Displays a TextBox and a TextLabel that shows the reverse of
		the TextBox's input in real time
	]]
	local TextReverser = Roact.Component:extend("TextReverser")

	function TextReverser:init()
		self.state = {
			text = "",
		}
	end

	function TextReverser:render()
		local text = self.state.text

		return Roact.createElement("Frame", {
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
				end,
			}),
			ReversedText = Roact.createElement(ReversedText, {
				layoutOrder = 2,
				inputText = text,
			}),
		})
	end

	local app = Roact.createElement("ScreenGui", nil, {
		TextReverser = Roact.createElement(TextReverser),
	})

	local handle = Roact.mount(app, PlayerGui)

	local function stop()
		Roact.unmount(handle)
	end

	return stop
end
