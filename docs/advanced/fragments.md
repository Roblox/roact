!!! info
	This section is a work in progress.

Typically, Roact components will render a single element by returning the result of a call to `createElement`. Suppose we'd instead like to create a Roact component that renders a collection of elements. That sort of component could be used to inject items into a list or frame without additional nesting.

For example, let's to define a list component like this:
```lua
local function ListComponent(props)
	return Roact.createElement("Frame", {
		-- Props for frame...
	}, {
		Layout = Roact.createElement("UIListLayout", {
			-- Props for UIListLayout...
		})
		ListItems = Roact.createElement(ListItems)
	})
end
```

The `ListItems` piece of our children will be defined by its own component that renders the contents of the list. To do this, we need to tell Roact explicitly that we'd like to render a collection of elements as children within the same parent.

That's where `Roact.createFragment` comes in:
```lua
local function ListItems(props)
	return Roact.createFragment({
		Item1 = Roact.createElement("TextLabel", {
			-- Props for item...
		}),
		Item2 = Roact.createElement("TextLabel", {
			-- Props for item...
		})
	})
end
```

This will work as expected when used in combination with the above `ListComponent`.