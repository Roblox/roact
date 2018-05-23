# Roact API Reference

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

### Roact.mount
```
Roact.mount(element, [parent, [key]]) -> ComponentInstanceHandle
```

!!! warning
	`Roact.mount` is also available via the deprecated alias `Roact.reify`. It will be removed in a future release.

Creates a Roblox Instance given a Roact element, and optionally a `parent` to put it in, and a `key` to use as the instance's `Name`.

The result is a `ComponentInstanceHandle`, which is an opaque handle that represents this specific instance of the root component. You can pass this to APIs like `Roact.unmount` and the future debug API.

### Roact.reconcile
```
Roact.reconcile(instanceHandle, element) -> ComponentInstanceHandle
```

Updates an existing instance handle with a new element, returning a new handle.

`reconcile` can be used to change the props of a component instance created with `mount` and is useful for putting Roact content into non-Roact applications.

!!! warning
	`Roact.reconcile` takes ownership of the `instanceHandle` passed into it and may unmount it and mount a new tree!

	Make sure to use the handle that `reconcile` returns in any operations after `reconcile`, including `unmount`.

### Roact.unmount
```
Roact.unmount(instance) -> void
```

!!! warning
	`Roact.unmount` is also available via the deprecated alias `Roact.teardown`. It will be removed in a future release.

Destroys the given `ComponentInstanceHandle` and all of its descendents. Does not operate on a Roblox Instance -- this must be given a handle that was returned by `Roact.mount`.

### Roact.oneChild
`Roact.oneChild(children) -> RoactElement | nil`

Given a dictionary of children, returns a single child element.

If `children` contains more than one child, `oneChild` function will throw an error. This is intended to denote an error when using the component using `oneChild`.

If `children` is `nil` or contains no children, `oneChild` will return `nil`.

## Constants

### Roact.Children
This is the key that Roact uses internally to store the children that are attached to a Roact element.

If you're writing a new functional or stateful element that needs to be used like a primitive component, you can access `Roact.Children` in your props table.

### Roact.Ref
Use `Roact.Ref` as a key into the props of a primitive element to receive a handle to the underlying Roblox Instance.

```lua
Roact.createElement("Frame", {
	[Roact.Ref] = function(rbx)
		print("Roblox Instance", rbx)
	end,
})
```

!!! warning
	`Roact.Ref` will be called with `nil` when the component instance is destroyed!

See [the refs guide](/advanced/refs.md) for more details.

### Roact.Event
Index into `Roact.Event` to receive a key that can be used to connect to events when creating primitive elements:

```lua
Roact.createElement("ImageButton", {
	[Roact.Event.MouseButton1Click] = function(rbx, x, y)
		print(rbx, "clicked at position", x, y)
	end,
})
```

!!! info
	Event callbacks receive the Roblox Instance as the first parameter, followed by any parameters yielded by the event.

!!! warning
	When connecting to the `Changed` event, be careful not to call `setState` or other functions that will trigger renders. This will cause Roact to re-render during a render, and errors will be thrown!

See [the events guide](/guide/events.md) for more details.

### Roact.Change
Index into `Roact.Change` to receive a key that can be used to connect to [`GetPropertyChangedSignal`](http://wiki.roblox.com/index.php?title=API:Class/Instance/GetPropertyChangedSignal) events.

It's similar to `Roact.Event`:

```lua
Roact.createElement("ScrollingFrame", {
	[Roact.Change.CanvasPosition] = function(rbx, position)
		print("ScrollingFrame scrolled to", position)
	end,
})
```

!!! warning
	Property changed events are fired by Roact during the reconciliation phase. Be careful not to accidentally trigger a re-render in the middle of a re-render, or an error will be thrown!

## Component Types

### Roact.Component
The base component instance that can be extended to make stateful components.

Call `Roact.Component:extend("ComponentName")` to make a new stateful component with a given name.

### Roact.PureComponent
An extension of `Roact.Component` that only re-renders if its props or state change.

`PureComponent` implements the `shouldUpdate` lifecycle event with a shallow equality comparison. It's optimized for use with immutable data structures, which makes it a perfect fit for use with frameworks like Rodux.

`PureComponent` is not *always* faster, but can often result in significant performance improvements when used correctly.

### Roact.Portal
A component that represents a *portal* to a Roblox Instance. Portals are created using `Roact.createElement`.

Any children of a portal are put inside the Roblox Instance specified by the required `target` prop. That Roblox Instance should not be one created by Roact.

Portals are useful for creating dialogs managed by deeply-nested UI components, and enable Roact to represent and manage multiple disjoint trees at once.

See [the Portals guide](/advanced/portals.md) for a small tutorial and more details about portals.

## Component API

### defaultProps
```
static defaultProps: Dictionary<any, any>
```

If `defaultProps` is defined on a stateful component, any props that aren't specified when a component is created will be taken from there.

### init
```
init(initialProps) -> void
```

`init` is called exactly once when a new instance of a component is created. It can be used to set up the initial `state`, as well as any non-`render` related values directly on the component.

`init` is the only place where you can assign to `state` directly, as opposed to using `setState`:

```lua
function MyComponent:init()
	self.state = {
		position = 0,
		velocity = 10
	}
end
```

### render
```
render() -> Element | nil
```

`render` describes what a component should display at the current instant in time.

!!! info
	Roact assumes that `render` act likes a pure function: the result of `render` must depend only on `props` and `state`, and it must not have side-effects.

```lua
function MyComponent:render()
	-- This is okay:
	return Roact.createElement("TextLabel", {
		Text = self.props.text,
		Position = self.state.position
	})

	-- Ack! Depending on values outside props/state is not allowed!
	return Roact.createElement("TextLabel", {
		Text = self.someText,
		Position = getMousePosition(),
	})
end
```

`render` must be defined for all components. The default implementation of `render` throws an error; if your component does not render anything, define a render function that returns `nil` explicitly.

```lua
function MyComponent:render()
	return nil
end
```

### setState
```
setState(newState) -> void
```

`setState` merges a table of new state values (`newState`) onto the existing `state` and re-renders the component if necessary. Existing values are not affected.

```lua
function MyComponent:didMount()
	self:setState({
		foo = "bar"
	})
end
```

!!! warning
	Calling `setState` from any of these places is not allowed and will throw an error:

	* Lifecycle hooks: `willUpdate`, `willUnmount`
	* Initialization: `init`
	* Pure functions: `render`, `shouldUpdate`

!!! info "Future API Changes"
	Depending on current `state` in `setState` may cause subtle bugs when Roact starts supporting [asynchronous rendering](https://github.com/Roblox/roact/issues/18).

	A new API similar to React [is being introduced](https://github.com/Roblox/roact/issues/33) to solve this problem. This documentation will be updated when that API is released.

### shouldUpdate
```
shouldUpdate(nextProps, nextState) -> bool
```

`shouldUpdate` provides a way to override Roact's rerendering heuristics.

Right now, components are re-rendered any time a parent component updates, or when state is updated via `setState`.

`PureComponent` implements `shouldUpdate` to only trigger a re-render any time the props are different based on shallow equality. In a future Roact update, *all* components may implement this check by default.

## Lifecycle Methods
In addition to the base Component API, Roact exposes additional lifecycle methods that stateful components can hook into to be notified of various steps in the rendering process.

<div align="center">
	<a href="../images/lifecycle.svg">
		<img src="../images/lifecycle.svg" alt="Diagram of Roact Lifecycle" />
	</a>
</div>

### didMount
```
didMount() -> void
```

`didMount` is fired after the component finishes its initial render. At this point, all associated Roblox Instances have been created, and all components have finished mounting.

`didMount` is a good place to start initial network communications, attach events to services, or modify the Roblox Instance hierarchy.

### willUnmount
```
willUnmount() -> void
```

`willUnmount` is fired right before Roact begins unmounting a component instance's children.

`willUnmount` acts like a component's destructor, and is a good place to disconnect any manually-connected events.

### willUpdate
```
willUpdate(nextProps, nextState) -> void
```

`willUpdate` is fired after an update is started but before a component's state and props are updated.

### didUpdate
```
didUpdate(previousProps, previousState) -> void
```

`didUpdate` is fired after at the end of an update. At this point, the reconciler has updated the properties of any Roblox Instances and the component instance's props and state are up to date.

`didUpdate` is a good place to send network requests or dispatch Rodux actions, but make sure to compare `self.props` and `self.state` with `previousProps` and `previousState` to avoid triggering too many updates.

### getDerivedStateFromProps
```
static getDerivedStateFromProps(nextProps, lastState) -> nextStateSlice
```

Used to recalculate any state that depends on being synchronized with `props`.

Generally, you should use `didUpdate` to respond to props changing. If you find yourself copying props values to state as-is, consider using props or memoization instead.

`getDerivedStateFromProps` should return a table that contains the part of the state that should be updated.

```lua
function MyComponent.getDerivedStateFromProps(nextProps, lastState)
	return {
		someValue = nextProps.someValue
	}
end
```

!!! note
	`getDerivedStateFromProps` is a *static* lifecycle method. It does not have access to `self`, and must be a pure function.

### validateProps
```
static validateProps(props) -> success, reason
```

Performs property validation. You can use this for type-checking properties; there is a [PropTypes](https://github.com/AmaranthineCodices/rbx-prop-types) library to assist in this.

This function will only be called if the `propertyValidation` configuration option is set to `true`. If this function returns `false`, the error message it returns will be thrown in the output, along with a stack trace pointing to the current element.

```lua
function MyComponent.validateProps(props)
	if props.requiredProperty == nil then
		return false, "requiredProperty is required"
	end

	return false
end
```

!!! note
	`validateProps`, like `getDerivedStateFromProps`, is a *static* lifecycle method. It does not have access to `self`, and must be a pure function.