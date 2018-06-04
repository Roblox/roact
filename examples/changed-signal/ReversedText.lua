--[[
	A TextLabel that display the given text in reverse.
]]
local Roact = require(game.ReplicatedStorage.Roact)

local function reverse(text)
	local result = ""

	if not text or text == "" then
		return result
	end

	for i = #text, 1, -1 do
		result = result .. text:sub(i, i)
	end

	return result
end

local function ReversedText(props)
	local inputText = props.inputText
	local layoutOrder = props.layoutOrder

	local reversedText = reverse(inputText)

	return Roact.createElement("TextLabel",{
		LayoutOrder = layoutOrder,
		Size = UDim2.new(1, 0, 0.5, 0),
		Text = "Reversed: " .. reversedText,
	})
end

return ReversedText