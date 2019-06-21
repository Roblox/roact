In all likelihood, the primary source of performance gains for your app will come from reducing the amount of work that Roact's reconcilation process requires. This is accomplished by:

* Indicating to Roact that some reconciliation work can be skipped
* Making sure your elements only change in ways you intended

## `shouldUpdate` Lifecycle Method
When a Roact Component's state or props change, it will call the Component's `shouldUpdate` method to determine whether or not to re-render it. The default implementation will always return true.
```lua
function Component:shouldUpdate(newProps, newState)
	return true
end
```

If you have a more complex component that only needs to re-render in certain situations, you can either use `PureComponent` (discussed below) or implement your own `shouldUpdate` and return `false` in any case where an update is not required.

!!! warning
	Manually implementing `shouldUpdate` is *dangerous*! If done carelessly, it can easily create confusing or subtle bugs.

	In most cases, the preferable solution is to use `PureComponent` instead, which has a simple and robust implementation of `shouldUpdate`.

## `PureComponent`
One common implementation of `shouldUpdate` is to do a shallow comparison between current and previous props and state. `Roact` provides an extension of `Roact.Component` called `Roact.PureComponent` that uses this implementation.

Let's use the following example:
```lua
local Item = Roact.Component:extend("Item")

function Item:render()
	local icon = self.props.icon
	local layoutOrder = self.props.layoutOrder

	-- Create a list item with the item's icon and name
	return Roact.createElement("ImageLabel", {
		LayoutOrder = layoutOrder,
		Image = icon,
	})
end

local Inventory = Roact.Component:extend("Inventory")

function Inventory:render()
	-- An Inventory contains a list of items
	local items = self.state.items

	local itemList = {}
	-- Create a UIListLayout to space out our items
	itemList["Layout"] = Roact.createElement("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
	})
	for i, item in ipairs(items) do
		-- Add the element to our list
		itemList[i] = Roact.createElement(Item, {
			layoutOrder = i,
			icon = item.icon,
		})
	end

	-- The Inventory renders a frame containing the list of Items as children
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 200, 0, 400)
	}, itemList)
end

```

In the above example, adding a new item to the `items` prop of the `Inventory` would cause all of the child `Item` elements to re-render, even if they haven't changed at all. This means if you add an item to an `Inventory` that already has 5 items, the result will be 6 renders of the `Item` component.

Lets change `Item` to a `PureComponent`:
```lua
local Item = Roact.PureComponent:extend("Item")
```
Now, if we add a new item to the end of the `Inventory` or change something about an existing item, we'll only re-render the `Inventory` itself and the modified `Item`!

!!! warning
	When working with `PureComponent`, it's critical to use immutable props. Immutability guarantees that a prop's reference will change any time its contents change.

!!! info
	There's more to discuss about immutability. It deserves a fully fleshed-out section somewhere!

## Stable Keys

Another performance improvement we can make is to use stable, unique keys to refer to our child elements.

When the list that we pass into the `Inventory` component changes, Roact updates our Roblox UI by adjusting the properties of each Roblox Instance according to the new list of elements.

For example, let's suppose our list of items is as follows:
```lua
{
	{ id = "sword", icon = swordIcon }, -- [1]
	{ id = "shield", icon = shieldIcon }, -- [2]
}
```

If we add a new item to the beginning, then we'll end up with a list like this:
```lua
{
	{ id = "potion", icon = potionIcon } -- [1]
	{ id = "sword", icon = swordIcon }, -- [2]
	{ id = "shield", icon = shieldIcon }, -- [3]
}
```

When Roact updates the underlying `ImageLabel` objects, it will need to change their icons so that the item at `[1]` has the potion icon, the item at `[2]` has the sword icon, and a new `ImageLabel` is added at `[3]` with the shield icon.

We'd like for Roact to know that the new item was added at `[1]` and that the sword and shield items simply moved down in the list. That way it can adjust their LayoutOrder properties and let the Roblox UI system resolve the rest.

So let's fix it! We'll make our list of `Item` elements use the item's id for its keys instead of the indexes in the `items` list:

```lua hl_lines="11 12"
function Inventory:render()
	-- An Inventory contains a list of items
	local items = self.state.items

	local itemList = {}
	itemList["Layout"] = Roact.createElement("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Vertical,
	})
	for i, item in ipairs(items) do
		-- Each element is now added at a stable key
		itemList[item.id] = Roact.createElement(Item, {
			layoutOrder = i,
			icon = item.icon,
		})
	end

	-- The Inventory renders a frame containing the list of Items as children
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 200, 0, 400)
	}, itemList)
end
```

Now the list of children is keyed by the stable, unique id of the item data. Their positions can change according to their LayoutOrder, but no other properties on the item need to be updated. When we add the third element to the list, Roact will set the `LayoutOrder` property on for each `ImageLabel` and only set the `Image` property on the newly added one!

!!! info
	Switching to static keys might seem insignificant for *this* example, but if our `Item` component becomes more complicated and our inventory gets bigger, it can make a significant difference!
