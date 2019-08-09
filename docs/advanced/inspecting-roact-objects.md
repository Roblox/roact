In certain situations, such as when building highly reusable and customizable components, props may be composed of Roact objects, such as an element or a component class.

To facilitate safer development for these kinds of situations, Roact exposes the `Roact.typeOf` function to inspect Roact objects and return a value from the `Roact.Type` enumeration.

## Without Object Type Inspection

Suppose we want to write a Header component with a prop for the title child element:
```lua
local Header = Component:extend("Header")
function Header:render()
	local titleClass = props.titleClass
	return Roact.createElement("Frame", {
		-- Props for Frame...
	}, {
		Title = Roact.createElement(titleClass, {
			-- Props for Title...
		})
	})
end
```

Now suppose we want to validate that titleClass is actually a class using [validateProps](../../api-reference/#validateprops). Unfortunately, the best we can do is query Header to see if it contains characteristics of a Component class:
```lua
local Header = Component:extend("Header")
Header.validateProps = function()
	local titleClass = props.titleClass
	if type(titleClass.render) == "function" then
		return true
	end
	return false, tostring(Header) .. " prop titleClass cannot render"
end
```

## With Object Type Inspection

With `Roact.typeOf`, we can be certain we have a Component class:
```lua
Header.validateProps = function()
	local titleClass = props.titleClass
	if Roact.typeOf(titleClass) == Roact.Type.StatefulComponentClass then
		return true
	end
	return false, tostring(Header) .. " prop titleClass is not a component class"
end
```

We can even provide props which can be of multiple different Roact object types to give the consumer more flexibility:
```lua
local Header = Component:extend("Header")
Header.validateProps = function()
	local title = props.title -- Type.Element | Type.StatefulComponentClass
	local titleType = Roact.typeOf(title)
	local isElement = titleType == Roact.Type.Element
	local isClass = titleType == Roact.Type.StatefulComponentClass
	if isElement or isClass then
		return true
	end
	return false, tostring(Header) .. " prop title must be a class or element"
end
function Header:render()
	local title = props.title
	local isElement = Roact.typeOf(title) == Roact.Type.Element
	local isClass = Roact.typeOf(title) == Roact.Type.StatefulComponentClass
	return Roact.createElement("Frame", {
		-- Props for Frame...
	}, {
		Title = isElement and title or isClass and Roact.createElement(title, {
			-- Props for Title...
		})
	})
end
```