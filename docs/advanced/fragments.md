!!! info
	This section is a work in progress.

Fragments are a tool for avoiding unnecessary nesting when organizing components. Typically, Roact components will render a single element by returning the result of a call to `createElement`.

For example, suppose for a multiplayer game we define a list component like this:
```lua
local function TeamList(props)
	return Roact.createElement("Frame", {
		-- Props for Frame...
	}, {
		Layout = Roact.createElement("UIListLayout", {
			-- Props for UIListLayout...
		})
		ListItems = Roact.createElement(TeamLabels)
	})
end
```

And a separate component to render a collection of `TextLabel`s that represent teams:
```lua
local function TeamLabels(props)
	return Roact.createElement("Frame", {
		-- Props for Frame...
	}, {
		RedTeam = Roact.createElement("TextLabel", {
			-- Props for item...
		}),
		BlueTeam = Roact.createElement("TextLabel", {
			-- Props for item...
		})
	})
end
```

Unfortunately, the `TeamLabels` piece of our children will be defined by its own component that renders the contents of the list. The resulting Roblox hierarchy won't actually apply the `UIListLayout` to the list of items, because it's grouped incorrectly:
```
Frame:
	UIListLayout
	Frame:
		TextLabel
		TextLabel
```

Suppose we'd instead like to create a Roact component that renders a collection of elements. That sort of component could be used to inject items into a list or frame without additional nesting. That's where fragments come in:
```lua hl_lines="2"
local function ListItems(props)
	return Roact.createFragment({
		RedTeam = Roact.createElement("TextLabel", {
			-- Props for item...
		}),
		BlueTeam = Roact.createElement("TextLabel", {
			-- Props for item...
		})
	})
end
```

We call `Roact.createFragment` and provide it a table of elements. When used in combination with the above `TeamList` component, this will generate the desired Roblox hierarchy:
```
Frame:
	UIListLayout
	TextLabel
	TextLabel
```

We are also free to create alternate views that use the same `TeamLabels` component with different Layouts or groupings.