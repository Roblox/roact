# Performance Guide
Roact operates on the principle that it's much easier to build UI declaratively. When something changes, the UI is rebuilt virtually and then the minimal necessary changes are made to the actual UI elements.

For simple projects, performance is unlikely to be an issue. But Roact is built in Lua, and Lua can be slow. There are a number of techniques that you can do to avoid performance strain with your Roact apps.

## Reduce Reconciliation

### `shouldUpdate` Lifecycle Method
When a Roact Component's state or props change, it will call the Component's `shouldUpdate` method to determine whether or not to re-render it. The default implementation will always returns true.
```lua
function Component:shouldUpdate(newProps, newState)
	return true
end
```

If you have a more complex component that only needs to re-render in certain situations, you can implement `shouldUpdate` and return `false` in any case where an update is not required.

### `PureComponent`
One common implementation of `shouldUpdate` is to do a shallow comparison between current and previous props and state. `Roact` provides an extension of `Roact.Component` called `Roact.PureComponent` that uses this implementation.

Let's use the following example:
```lua
local Item = Roact.Component:extend("Item")

function Item:render()
	local icon = self.props.icon

	-- Create an ImageLabel with the item's icon
	return Roact.createElement("ImageLabel", {
		Image = icon,
	})
end

local Inventory = Roact.Component:extend("FriendList")

function Inventory:render()
	-- An Inventory contains a list of items
	local items = self.props.items

	local itemList = {}
	for _, item in ipairs(items) do
		-- Add an element for each item
		itemList[i] = Roact.createElement(Item, {
			icon = item.icon
		})
	end

	-- The Inventory renders a frame containing the list of Items as children
	return Roact.createElement("Frame", {}, itemList)
end

```

In the above example, adding a new item to the `items` prop of the `Inventory` would cause all of the child `Item` elements to re-render, even if they haven't changed at all. This means if you add an item to an `Inventory` that already has 5 items, the result will be 6 renders of the `Item` component.

Lets change `Item` to a `PureComponent`:
```lua
local Item = Roact.PureComponent:extend("Item")
```
Now, if we add a new item to the `Inventory` or change something about an existing item, we'll only re-render the `Inventory` itself and the modified `Item`!

### Immutable Props

Immutable props are critical to properly using `PureComponent`. They ensure that any prop that is a list or a table will always change when its contents change.

!!! info
	This section is incomplete! It should link to a fully fleshed-out Immutability section