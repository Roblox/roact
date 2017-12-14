# Elements and Components
Roact is based entirely on the concept of reusable components. These components are then built up entirely of other components, creating a composable hierarchy that represents the UI of an application.

## Elements
Elements are directly created by a Roact application calling `Roact.createElement`. They represent the structure that should be presented at any given point.

Elements are immutable, fast to create, and replaceable. Creating an element has no side effects since all it does is describe what your UI should look like.

## Components
Components define what happens when your elements need to be translated to a real UI.

There are three types of component:
* Primitive
* Functional
* Stateful

Roact will take the tree of *elements*, which themselves specify what types of *component* they represent. With that tree, it'll create *component instances*, which represent a specific invocation of the UI.

### Primitive Components
Primitive components correlate one-to-one with Roblox Instances, like `Frame`, `ScreenGui`, or `Part` objects.

```lua
local element = Roact.createElement("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = Color3.new(1, 0, 0),
})

Roact.reify(element, CoreGui, "Really Red Frame")
```

This code will create a `Frame` named `"Really Red Frame"` and stick it into `CoreGui`.

Primitive components are allowed to have multiple children, which can also turn into Roblox Instances:

```lua
local list = Roact.createElement("Frame", {
	Size = UDim2.new(1, 0, 1, 0),
}, {
	Layout = Roact.createElement("UIListLayout"),

	A = Roact.createElement("TextButton"),
	B = Roact.createElement("TextButton"),
})
```

When reified, this component would produce this Roblox hierarchy:

```
Frame
	- UIListLayout (named 'Layout')
	- TextButton (named 'A')
	- TextButton (named 'B')
```

### Functional Components
Functional components are just functions that take in some values (named `props`), and return an element or `nil`.

```lua
local function CoolLabel(props)
	local text = props.text

	return Roact.createElement("TextLabel", {
		Text = text,
	})
end
```

To use them, just create an element that references one as your type, just like with primitive elements:

```lua
local myLabel = Roact.createElement(CoolLabel, {
	text = "henlo my guys"
})

Roact.reify(myLabel, CoreGui, "Hip Greeting")
```

Functional elements can have children too, you just have to explicitly access and use them:

```lua
local function StuffContainer(props)
	local children = props[Roact.Children]

	return Roact.createElement("Frame", {
		Size = UDim2.new(1, 0, 1, 0)
	}, children)
end

local element = Roact.createElement(StuffContainer, {}, {
	A = Roact.createElement("TextButton"),
	B = Roact.createElement("Frame"),
})
```

When reified, `element` would result in this Roblox hierarchy:

```
Frame
	- TextButton (named 'A')
	- Frame (named 'B')
```

### Stateful Components
*Functions are to classes as functional components are to stateful components.*

Stateful components are very similar to functional components in that the meat of their code is just a function that returns an element or `nil`:

```lua
local CoolLabel = Roact.Component:extend("CoolLabel")

function CoolLabel:render()
	local text = self.props.text

	return Roact.createElement("TextLabel", {
		Text = text
	})
end
```

**It's important that the `render` function in a stateful component *only* uses values from `props` and `state` to determine what to render!**

The primary difference here is that you call `extend` on `Roact.Component`, passing in a name to give to your new component. This name is used for debugging.

Stateful components also have a notion of state, which lets them keep track of their own data that can change. See [the 'counter' example](/examples/counter.md) for a good example of how to utilize state.

### Higher-Order Components (HOC)
A higher-order component (or HOC) is just a function that returns a component. It's a common pattern for APIs like Roact-Rodux that wrap an existing component with some extra features.