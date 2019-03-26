Fragments are a tool for avoiding unnecessary nesting when organizing components by allowing components to render collections of elements without wrapping them in a single containing element.

## Without Fragments

Typically, Roact components will render a single element via `createElement`. For example, suppose we define a component like this:
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

Suppose we also want to use a separate component to render a collection of `TextLabel`s:
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

Unfortunately, the `TeamLabels` component can't return two different labels without wrapping them in a containing frame. The resulting Roblox hierarchy from these `TeamList` component won't actually apply the `UIListLayout` to the list of items, because it's grouped incorrectly:
```
Frame:
	UIListLayout
	Frame:
		TextLabel
		TextLabel
```

## With Fragments

In order to separate our list contents from our list container, we need to be able to return a group of elements from our render method rather than a single one. Fragments make this possible:
```lua hl_lines="2"
local function TeamLabels(props)
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

We provide `Roact.createFragment` with a table of elements. These elements will result in multiple children of this component's parent. When used in combination with the above `TeamList` component, it will generate the desired Roblox hierarchy:
```
Frame:
	UIListLayout
	TextLabel
	TextLabel
```

We are also free to create alternate views that use the same `TeamLabels` component with different Layouts or groupings.