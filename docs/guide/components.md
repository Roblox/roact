Components are encapsulated, reusable pieces of UI that you can combine to build a complete UI.

Components accept inputs, known as *props*, and return elements to describe the UI that should represent those inputs.

## Types of Components

### Host Components
A *host* component is nothing more than a string that matches the name of a Roblox class. We used these in our earlier discussion about [elements](../elements) as the first argument to `createElement`. Examples include `"Frame"`, `"ImageButton"`, etc.

When our component is a host component, the props that we pass to it will be turned directly into properties on the Roblox instance that the component refers to.

### Function Components
*Function* components are the simplest kind of user-defined component: they're just functions that accept props as their only argument, and return some elements.

```lua
local function Greeting(props)
	return Roact.createElement("TextLabel", {
		Text = "Hello, " .. props.name
	})
end
```

### Stateful Components
Roact also has *stateful* components, which provide additional features like lifecycle methods and state. We'll talk about these features in a later section.

You can create a stateful component by calling `Roact.Component:extend` and passing in the component's name.

```lua
local Greeting = Roact.Component:extend("Greeting")

function Greeting:render()
	return Roact.createElement("TextLabel", {
		Text = "Hello, " .. self.props.name
	})
end
```

## Using Components
In our previous examples, we passed strings to `Roact.createElement` to create elements that represented Roblox Instances.

We can also pass our custom components to create elements that represent them:

```lua
local hello = Roact.createElement(Greeting, {
	name = "Rick James"
})
```

The `name` value is passed to our component as props, which we can reference as the `props` argument in our function component or `self.props` in our stateful component.

## Components in Components
Components are designed to make it easy to re-use pieces of UI, so naturally, we can use components inside other components!

```lua
local function Greeting(props)
	return Roact.createElement("TextLabel", {
		Text = "Hello, " .. props.name
	})
end

local function GreetEveryone()
	return Roact.createElement("ScreenGui", {}, {
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

## Incrementing Counter, Part Two
We can revisit the incrementing counter example from the previous section, now using a function component. Changed sections are highlighted.

```lua hl_lines="6 7 8 23 24 25 26 33 34 35"
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Roact)

-- Create a function component that represents our UI
local function Clock(props)
	local currentTime = props.currentTime

	return Roact.createElement("ScreenGui", {}, {
		TimeLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Text = "Time Elapsed: " .. currentTime
		})
	})
end

local PlayerGui = Players.LocalPlayer.PlayerGui

-- Create our initial UI.
local currentTime = 0

local clockElement = Roact.createElement(Clock, {
	currentTime = currentTime
})
local handle = Roact.mount(clockElement, PlayerGui, "Clock UI")

-- Every second, update the UI to show our new time.
while true do
	wait(1)

	currentTime = currentTime + 1
	handle = Roact.update(handle, Roact.createElement(Clock, {
		currentTime = currentTime
	}))
end
```
