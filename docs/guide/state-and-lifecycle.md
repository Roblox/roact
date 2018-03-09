# State and Lifecycle
In the previous section, we talked about using components to create reusable chunks of state, and introduced *functional* and *stateful* components.

Stateful components do everything that functional components do, but have the addition of mutable *state* and *lifecycle methods*.

## State
TODO

## Lifecycle Methods
(diagram of lifecycle methods)

Stateful components can provide methods to Roact that are called when certain things happen to a component instance.

Lifecycle methods are a great place to send off network requests, measure UI ([with the help of refs](/advanced/refs)), wrap non-Roact components, and other side-effects.

## Combining State and Lifecycle