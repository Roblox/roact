# Components
Components are encapsulated, reusable pieces of UI that you can combine to build a complete UI.

Components accept inputs, known as *props*, and return elements to describe the UI that should represent those inputs.

## Functional and Stateful Components
Components come in two flavors in Roact, *functional* and *stateful*.

Functional components are the simplest: they're just functions that accept props as their only argument, and return some elements.

```lua
-- A functional component
local function Greeting(props)
	return Roact.createElement("TextLabel", {
		Text = "Hello, " .. props.name
	})
end
```

Roact also has *stateful* components, which have additional features, like lifecycle methods and state, that we'll talk about in a later section.

```lua
-- A stateful component
local Greeting = Roact.Component:extend("Greeting")

function Greeting:render()
	return Roact.createElement("TextLabel", {
		Text = "Hello, " .. self.props.name
	})
end
```

## Using Components
In our previous examples, we passed strings to `Roact.createElement` to create elements that represented Roblox Instances.

We can also use components to create elements that represent them:

```lua
local hello = Roact.createElement(Greeting, {
	name = "James"
})
```

The `name` value is passed to our component as props, which we can reference as `props` in our functional component or `self.props` in our stateful component.

## Components in Components
Naturally, we can use components inside other components!

```lua
local function Greeting(props)
	return Roact.createElement("TextLabel", {
		Text = "Hello, " .. props.name
	})
end

local function GreetEveryone()
	return Roact.createElement("ScreenGui", {
		Layout = Roact.createElement("UIListLayout"),

		HelloJoe = Roact.createElement(Greeting, {
			name = "Joe"
		}),

		HelloMary = Roact.createElement(Greeting, {
			name = "Mary"
		})
	})
end
```

Applications built using Roact usually have one component at the top of the tree, and include all other pieces as children.