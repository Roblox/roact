--[[
	A TextBox that the user can type into. Takes a callback to be
	triggered when text changes.
]]
local Roact = require(game.ReplicatedStorage.Roact)

local function InputTextBox(props)
	local onTextChanged = props.onTextChanged
	local layoutOrder = props.layoutOrder

	return Roact.createElement("TextBox",{
		LayoutOrder = layoutOrder,
		Text = "Type Here!",
		Size = UDim2.new(1, 0, 0.5, 0),
		[Roact.Change.Text] = onTextChanged
	})
end

return InputTextBox