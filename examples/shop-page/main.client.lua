local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Components = ReplicatedStorage:WaitForChild("Components")

local Roact = require(ReplicatedStorage.Roact)

local ShopPage = require(Components:WaitForChild("ShopPage"))

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local shopPage = Roact.createElement(ShopPage, {
	items = {
		{
			identifier = "SmallCoinPack",
			image = "https://www.roblox.com/bust-thumbnail/image?userId=3370645&width=420&height=420&format=png",
			price = 30,
		},
		{
			identifier = "LargeCoinPack",
			image = "https://www.roblox.com/bust-thumbnail/image?userId=3370645&width=420&height=420&format=png",
			price = 50,
		},
		{
			identifier = "MediumCoinPack",
			image = "https://www.roblox.com/bust-thumbnail/image?userId=3370645&width=420&height=420&format=png",
			price = 40,
		},
	},
	itemAspectRatio = 1,
	itemsPerRow = 3,
	padding = 10,
	AnchorPoint = Vector2.new(0.5, 0.5),
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Size = UDim2.new(0.5, 0, 0.5, 0),
})

local handle = Roact.mount(shopPage, screenGui)
