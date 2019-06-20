local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage:WaitForChild("Components")

local Roact = require(ReplicatedStorage.Roact)

local ProductItem = require(Components:WaitForChild("ProductItem"))

--[[
	Props: {
		items: list of product items following this structure
		{
			identifier = string,
			price = number,
			order = optional number,
		}
	}
]]
local function ProductItemList(props)
	local elements = {}

	for i=1, #props.items do
		local item = props.items[i]

		elements[item.identifier] = Roact.createElement(ProductItem, {
			image = item.image,
			price = item.price,
			order = item.order,
		})
	end

	return Roact.createFragment(elements)
end

return ProductItemList