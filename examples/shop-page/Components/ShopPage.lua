local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Components = ReplicatedStorage:WaitForChild("Components")

local Roact = require(ReplicatedStorage.Roact)

local ProductItemList = require(Components:WaitForChild("ProductItemList"))

local ShopPage = Roact.Component:extend("ShopPage")

ShopPage.defaultProps = {
	padding = 0,
}

function ShopPage:init()
	self:setState({
		cellSize = 100,
		canvasHeight = 100,
	})

	self.onAbsoluteSizeChanged = function(frame)
		local props = self.props
		local state = self.state
		local padding = props.padding
		local itemsPerRow = props.itemsPerRow

		local totalWidth = frame.AbsoluteSize.X
		local cellWidth = (totalWidth - padding * (itemsPerRow + 1)) / itemsPerRow
		local cellHeight = cellWidth * props.itemAspectRatio
		local rows = math.ceil(#props.items / itemsPerRow)
		local canvasHeight = rows * cellHeight + padding * (rows + 1)

		self:setState({
			cellSize = cellWidth,
			canvasHeight = canvasHeight,
		})
	end
end

function ShopPage:render()
	local props = self.props
	local state = self.state
	local padding = props.padding
	local cellSize = state.cellSize
	local canvasHeight = state.canvasHeight

	local frameProps = {}

	for key, value in pairs(props.frameProps) do
		frameProps[key] = value
	end

	frameProps.CanvasSize = UDim2.new(0, 0, 0, canvasHeight)
	frameProps.ClipsDescendants = true
	frameProps[Roact.Change.AbsoluteSize] = self.onAbsoluteSizeChanged

	return Roact.createElement("ScrollingFrame", frameProps, {
		UIGrid = Roact.createElement("UIGridLayout", {
			CellPadding = UDim2.new(0, padding, 0, padding),
			CellSize = UDim2.new(0, cellSize, 0, cellSize * props.itemAspectRatio),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		ProductItems = Roact.createElement(ProductItemList, {
			items = props.items
		}),
	})
end

function ShopPage.validateProps(props)
	return pcall(function()
		assert(
			type(props.padding) == "number",
			("props.padding should be a number (got %q)"):format(type(props.padding))
		)
		assert(
			type(props.frameProps) == "table",
			("props.frameProps should be a table (got %q)"):format(type(props.frameProps))
		)
	end)
end

return ShopPage