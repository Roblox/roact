!!! danger "Unreleased API"
	This API is not yet available in a stable Roact release.

	It may be available from a recent pre-release or Roact's master branch.

[TOC]

Roact supports a feature known as context that helps pass values down the tree without having to pass them through props.

## Basic Usage
Context is defined by creating a pair of components known as the _Provider_ and the _Consumer_. Roact does this for you with the `Roact.createContext()` API:

```lua
local MyValueContext = Roact.createContext()
```

## Example: Theming


## Legacy Context
Roact also has a deprecated version of context that pre-dates the stable context API. It will be removed in a future release, but is currently maintained for backwards-compatibility.