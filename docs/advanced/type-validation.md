In certain situations, such as when building reusable and customizable components, props may be composed of Roact objects, such as an element or a component.

To facilitate safer development for these kinds of situations, Roact provides the `Roact.typeOf` and `Roact.isComponent` functions to help validate these objects.

## Without Type Validation

Suppose we want to write a `Header` component with a prop for the title child element:
```lua
local Header = Component:extend("Header")

function Header:render()
	local title = props.title

	return Roact.createElement("Frame", {
		-- Props for Frame...
	}, {
		Title = title
	})
end
```

Now suppose we want to validate that `title` is actually an element using [validateProps](../../api-reference/#validateprops). Without a type checking function, `title` must be queried to check for characteristics of an element:
```lua
Header.validateProps = function()
	local title = props.title

	if title.component then
		return true
	end

	return false, tostring(Header) .. " prop title is not an element"
end
```
This approach is fragile, since it relies on undocumented internals.

## Roact Object Type Validation

With `Roact.typeOf` we can be certain we have a Roact Element:
```lua
Header.validateProps = function()
	local title = props.title

	if Roact.typeOf(title) == Roact.Type.Element then
		return true
	end

	return false, tostring(Header) .. " prop title is not an element"
end
```

## Component Type Validation

In some cases, a component will be more preferable as a prop than an element.  `Roact.isComponent` can be used to see if a value is a plausible component and thus can be passed to `Roact.createElement`.

```lua
local Header = Component:extend("Header")

Header.validateProps = function()
	local title = props.title

	if Roact.isComponent(title) then
		return true
	end

	return false, tostring(Header) .. " prop title can not be an element"
end

function Header:render()
	local title = props.title
	return Roact.createElement("Frame", {
		-- Props for Frame...
	}, {
		Title = Roact.isComponent(title) and Roact.createElement(title, {
			-- Props for Title...
		})
	})
end
```

!!! info
	Because strings (hosts) and functions are valid component types, `Roact.isComponent` is less safe than `Roact.typeOf`. If safety is paramount, consider only allowing component classes, and checking that the `typeOf` the prop is `Roact.Type.StatefulComponentClass`.