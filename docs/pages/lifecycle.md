# Lifecycle
Roact calls special *lifecycle* events on stateful components that can be overridden.

These are:
* `didMount()`, called after the component and its children are fully created
* `willUnmount()`, called just before the component is destroyed
* `shouldUpdate(nextProps, nextState)`, called to decide whether to update, or ignore a change
* `willUpdate(nextProps, nextState)`, called just before the component is given new props/state
* `didUpdate(prevProps, prevState)`, called after the component handled an update

To use them, define the appropriate methods on a stateful component:

```lua
local TestComponent = Roact.Component:extend("TestComponent")

-- We have to override this for every component
function TestComponent:render()
	return nil
end

function TestComponent:didMount()
	print("We were mounted!")
end

function TestComponent:willUnmount()
	print("We're about to unmount!")
end
```