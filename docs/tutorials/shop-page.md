# Shop page
_Goal: Create a page to sell developer products in a game._

[add an image of the result we are expecting]

## Top Component
Let's start by creating the top level component, that will be the page containing the items for sale in the game. When creating a new component, we need to think about what will this component manage itself and what will be given to that component from the parent component.

In our case, the ShopPage component we're making will receive it's products from a parent component: that means that the product items will be received as props in our component.

> Props or state?
>
> This is a question that often comes to our mind when we start working Roact. Remember that state is internal to the component. Things that are relevant only to a component should go in the state.
>
> On the other hand, props are used to pass data from parent components to child components. It implies that both parent component and it's child are aware of the structure of the props dictionary and depends on it.

For our first draft of the component, we will define some props to be able to pass parameters to customize our shop page. We will start by adding the following:
 - frameProps: a dictionary of props that will be passed to the scrolling frame to change it's visuals
 - items: a list of table that represents our products we want to sell
 - padding: the number of pixels between each of our items in the shop-page

```lua
local ShopPage = Roact.Component:extend("ShopPage")

function ShopPage:render()
	local props = self.props

	local items = props.items
	local frameProps = props.frameProps
	local padding = props.padding

	return Roact.createElement("ScrollingFrame", frameProps, {
		UIGrid = Roact.createElement("UIGridLayout", {
			CellPadding = UDim2.new(0, padding, 0, padding),
			CellSize = UDim2.new(0, 100, 0, 100),
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		ProductItems = Roact.createElement(ProductItemList, {
			items = items
		}),
	})
end

return ShopPage
```

As you can see, the `frameProps` are passed to the ScrollingFrame creation! That way, we can control how the container look from outside the parent of the component.

### Viewing the component

Now that we have started working on our first component, we want to be able to see the results. To do that, let's create a LocalScript that will put out component in context. This script needs to _mount_ our ShopPage into a parent that will simply be a ScreenGui.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Components = ReplicatedStorage:WaitForChild("Components")

local Roact = require(ReplicatedStorage.Roact)

local ShopPage = require(Components:WaitForChild("ShopPage"))

local screenGui = Instance.new("ScreenGui")
screenGui.Parent = Players.LocalPlayer:WaitForChild("PlayerGui")

local shopPage = Roact.createElement(ShopPage, {
	items = {}, -- we're not ready for this yet so it's just an empty list
	frameProps = {
		-- here we define the properties of our ShopPage scrolling frame
		AnchorPoint = Vector2.new(0.5, 0.5),
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0.5, 0, 0.5, 0),
	},
	padding = 10,
})

Roact.mount(shopPage, screenGui)
```

The two important things to notice here are:
 - an element is created from our ShopPage component, where we specified the different props we want
 - `Roact.mount` will create the real UI objects we need to see the results

## Items Grid


## Product Item
[remind state and props]
[props validation]

### Adding some animations


## Integration

### In a Roact project
Here explain how the component can be used my another component or how it can be mounted on it's own (like main.client.lua does)

### In a non-Roact project
Explain how the page could be mounted in an existing UI instances tree. That opens the subject that it is possible to slowly port an existing UI to use Roact part by part.
