local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Components = ReplicatedStorage:WaitForChild("Components")

local Roact = require(ReplicatedStorage.Roact)

Roact.setGlobalConfig({
	propValidation = true
})

local ShopPage = require(Components:WaitForChild("ShopPage"))

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local shopPage = Roact.createElement(ShopPage, {
	items = {
		{
			identifier = "Red Visor",
			image = "https://www.roblox.com/asset-thumbnail/image?assetId=139618072&width=420&height=420&format=png",
			price = 30,
			productId = 0,
		},
		{
			identifier = "Green Visor",
			image = "https://www.roblox.com/asset-thumbnail/image?assetId=20264649&width=420&height=420&format=png",
			price = 50,
			productId = 0,
		},
		{
			identifier = "Yellow Visor",
			image = "https://www.roblox.com/asset-thumbnail/image?assetId=7135977&width=420&height=420&format=png",
			price = 40,
			productId = 0,
		},
		{
			identifier = "Blue Visor",
			image = "https://www.roblox.com/asset-thumbnail/image?assetId=1459035&width=420&height=420&format=png",
			price = 55,
			productId = 0,
		},
		{
			identifier = "Dark Blue Visor",
			image = "https://www.roblox.com/asset-thumbnail/image?assetId=68268372&width=420&height=420&format=png",
			price = 60,
			productId = 0,
		},
		{
			identifier = "Purple Visor",
			image = "https://www.roblox.com/asset-thumbnail/image?assetId=334661971&width=420&height=420&format=png",
			price = 100,
			productId = 0,
		},
	},
	itemAspectRatio = 1,
	itemsPerRow = 3,
	padding = 10,
	frameProps = {
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0.5, 0),
	},
})

local handle = Roact.mount(shopPage, screenGui)
