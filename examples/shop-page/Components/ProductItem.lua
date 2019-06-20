local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Roact)

local ProductItem = Roact.Component:extend("ProductItem")

--[[
	Props: {
		image: the image displayed
		price: how much robux the product cost
		productId: the developer product id

		-- Optional props
		order: the index at which the item should be shown. If not
		       provided, the price will be used as the index.
	}
]]

function ProductItem:init()
	self:setState({
		onMouseEnter = function()
			-- grow the icon a little
		end,
		onMouseLeave = function()
			-- go back to original size
		end,
		onActivated = function()
			local props = self.props

			MarketplaceService:PromptProductPurchase(Players.LocalPlayer, props.productId)
		end
	})
	self.padding, self.updatePadding = Roact.createBinding(0)
end

function ProductItem:render()
	local props = self.props
	local state = self.state
	local padding = self.padding

	return Roact.createElement("ImageButton", {
		BackgroundTransparency = 1,
		Image = '',
		LayoutOrder = props.order or props.price,
		[Roact.Event.MouseEnter] = state.onMouseEnter,
		[Roact.Event.MouseLeave] = state.onMouseLeave,
	}, {
		Icon = Roact.createElement("ImageLabel", {
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundTransparency = 1,
			Image = props.image,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(1, padding, 1, padding),
		}),
		PriceLabel = Roact.createElement("TextLabel", {
			AnchorPoint = Vector2.new(0.5, 1),
			BackgroundTransparency = 1,
			Text = ("R$ %d"):format(props.price),
			TextColor3 = Color3.fromRGB(10, 200, 10),
			TextScaled = true,
			Position = UDim2.new(0.5, 0, 1, 0),
			Size = UDim2.new(1, 0, 0.3, 0),
		}),
	})
end

return ProductItem