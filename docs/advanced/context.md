!!! success "Added in Roact 1.3.0"

[TOC]

Roact supports a feature called context which enables passing values down the tree without having to pass them through props. Roact's Context API is based on [React's Context API](https://reactjs.org/docs/context.html).

Context is commonly used to implement features like dependency injection, dynamic theming, and scoped state storage.

## Basic Usage
```lua
local ThemeContext = Roact.createContext(defaultValue)
```

Context objects contain two components, `Consumer` and `Provider`.

The `Consumer` component accepts a `render` function as its only prop, which is used to render its children. It's passed one argument, which is the context value from the nearest matching `Provider` ancestor.

If there is no `Provider` ancestor, then `defaultValue` will be passed instead.

```lua
local function ThemedButton(props)
	return Roact.createElement(ThemeContext.Consumer, {
		render = function(theme)
			return Roact.createElement("TextButton", {
				Size = UDim2.new(0, 100, 0, 100),
				Text = "Click Me!",
				TextColor3 = theme.foreground,
				BackgroundColor3 = theme.background,
			})
		end
	})
end
```

The `Provider` component accepts a `value` prop as well as children. Any of its descendants will have access to the value provided to it by using the `Consumer` component like above.

Whenever the `Provider` receives a new `value` prop in an update, any attached `Consumer` components will re-render with the new value. This value could be externally controlled, or could be controlled by state in a component wrapping `Provider`:

```lua
local ThemeController = Roact.Component:extend("ThemeController")

function ThemeController:init()
	self:setState({
		theme = {
			foreground = Color3.new(1, 1, 1),
			background = Color3.new(0, 0, 0),
		}
	})
end

function ThemeController:render()
	return Roact.createElement(ThemeContext.Provider, {
		value = self.state.theme,
	}, self.props[Roact.Children])
end
```

## Legacy Context
!!! danger
	Legacy Context is a deprecated feature that will be removed in a future release of Roact.

Roact also has a deprecated version of context that pre-dates the stable context API.

Legacy context values **do not update dynamically** on their own. It is up to the context user to create their own mechanism for updates, probably using a wrapper component and `setState`.

To use it, add new entries to `self._context` in `Component:init()` to create a provider:

```lua
local Provider = Roact.Component:extend("FooProvider")

-- Using a unique non-string key is recommended to avoid collisions.
local FooKey = {}

function Provider:init()
	self._context[FooKey] = {
		value = 5,
	}
end
```

...and read from that same value in `Component:init()` in your consumer component:

```lua
local Consumer = Roact.Component:extend("FooConsumer")

function Consumer:init()
	self.foo = self._context[FooKey]
end

function Consumer:render()
	return Roact.createElement("TextLabel", {
		Text = "Foo: " .. self.foo.value,
	})
end
```