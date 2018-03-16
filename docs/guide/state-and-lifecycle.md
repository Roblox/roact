# State and Lifecycle
In the previous section, we talked about using components to create reusable chunks of state, and introduced *functional* and *stateful* components.

Stateful components do everything that functional components do, but have the addition of mutable *state* and *lifecycle methods*.

## State
TODO

## Lifecycle Methods
Stateful components can provide methods to Roact that are called when certain things happen to a component instance.

Lifecycle methods are a great place to send off network requests, measure UI ([with the help of refs](/advanced/refs)), wrap non-Roact components, and other side-effects.

A [diagram of Roact's lifecycle methods](/api-reference#lifecycle-events) is available in the API reference.

## Combining State and Lifecycle