# Roact Internals Design
This doc is intended to be your guide to understanding Roact's internals.

## Table of Contents
1. [Glossary](#glossary)

## Glossary

### Component
Components are referenced by [Elements](#element) and used as a discriminant.

Components come in a few different flavors:

* Host components, of type `string`
* Function components, of type `function`
* Stateful components, of type `table` with a `Type` tag of `StatefulComponentClass`
* Portals, of type `userdata`, equal to `Core.Portal`

Host components are given meaning by the [Renderer](#renderer). In the context of Roblox, they're string names referring to [Roblox Instances](#roblox-instance).

Function components are defined by consumers of Roact. They're just functions that accept `props` as their only argument and return zero or more elements:

```lua
local function Cool(props)
	return Roact.createElement("Frame")
end
```

Stateful components are also defined by consumers of Roact. They're created by calling the `extend` method of either `Component` or `PureComponent`:

```lua
-- `extend` requires a name for debugging purposes
local Cooler = Roact.Component:extend("Cooler")

-- OR
local Cooler = Roact.PureComponent:extend("Cooler")

-- `render` is required to be defined
function Cooler:render()
	return Roact.createElement("Frame")
end
```

Consumers of Roact creating stateful components must define `render`. They can also optionally define a handful of lifecycle methods that Roact will invoke at different points.

#### `didMount()`
Called when Roact has constructed a component instance. This is used for side effects like manually manipulating [Roblox Instances](#roblox-instance), measuring UI elements, and kicking off network requests.

#### `willUnmount()`
Called when Roact is about to destroy this component instance.

#### `willUpdate(nextProps, nextState)`
Called when Roact is about to update this component instance. It's called when the component instance's props updated from above, or when someone invoked `componentInstance:setState(newState)`.

**We want to deprecate this.** Most uses of `willUpdate` are better served by `getDerivedStateFromProps`, and this is a change that React has already made in order to better support asynchronous rendering.

#### `didUpdate(previousProps, previousState)`
Called when Roact just performed an update. It's called under the same circumstances as `willUpdate`.

#### `static getDerivedStateFromProps(props, state)`
Called whenever there's an update to the component's state or props. It's a `static` method, meaning it doesn't get access to the component instance.

### Element

### Virtual Tree

### Virtual Node

### Reconciler

### Renderer

### Roblox Instance