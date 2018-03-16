# Roact API Reference

## Objects

### Roact.Component
The base component instance that can be extended to make stateful components.

Call `Roact.Component:extend("ComponentName")` to make a new stateful component with a given name.

### Roact.PureComponent
An extension of `Roact.Component` that only re-renders if its props or state change.

`PureComponent` implements `shouldUpdate` with a sane default. It's possible that `PureComponent` could be slower than doing a wasteful re-render, so measure!

## Constants

### Roact.Children
This is the key that Roact uses internally to store the children that are attached to a Roact element.

If you're writing a new functional or stateful element that needs to be used like a primitive component, you can access `Roact.Children` in your props table.

### Roact.Ref
Used to access underlying Roblox instances. See [the refs example](/examples/refs.html) for more details.

### Roact.Event
Index into this object to get handles that can be used for attaching events to Roblox objects. See [the events example](/examples/events.md) for more details.

## Methods

### Roact.createElement
```
Roact.createElement(component, [props, [children]]) -> RoactElement
```

Creates a new Roact element representing the given `component`.

The `children` argument is shorthand for adding a `Roact.Children` key to `props`. It should be specified as a dictionary of names to elements.

`component` can be a string, a function, or a table created by `Component:extend`.

!!! caution
	Once `props` or `children` are passed into the `createElement`, make sure not to modify them!

### Roact.reify
```
Roact.reify(element, [parent, [key]]) -> RoactComponentInstance
```

Creates a Roblox Instance given a Roact element, and optionally a `parent` to put it in, and a `key` to use as the instance's `Name`.

The result is a `RoactComponentInstance`, which is an opaque handle that represents this specific instance of the root component. You can pass this to APIs like `Roact.teardown` and the future debug API.

### Roact.teardown
```
Roact.teardown(instance)
```

Destroys the given `RoactComponentInstance` and all of its descendents. Does not operate on a Roblox Instance -- this must be given a handle that was returned by `Roact.reify`.

### Roact.oneChild
`Roact.oneChild(children) -> RoactElement | nil`

Given a dictionary of children, returns a single child element.

If `children` contains more than one child, `oneChild` function will throw an error. This is intended to denote an error when using the component using `oneChild`.

If `children` is `nil` or contains no children, `oneChild` will return `nil`.
