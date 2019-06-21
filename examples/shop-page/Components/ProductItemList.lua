local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Components = ReplicatedStorage:WaitForChild("Components")

local Roact = require(ReplicatedStorage.Roact)

local ProductItem = require(Components:WaitForChild("ProductItem"))

local function ProductItemList(props)
	local elements = {}

	for i=1, #props.items do
		local item = props.items[i]

		elements[item.identifier] = Roact.createElement(ProductItem, {
			image = item.image,
			price = item.price,
			productId = item.productId,
			order = item.order,
		})
	end

	return Roact.createFragment(elements)
end

return ProductItemList