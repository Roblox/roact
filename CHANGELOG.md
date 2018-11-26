# Roact Changelog

## Current `master` branch
* Renamed `Roact.reify` to `Roact.mount` and `Roact.teardown` to `Roact.unmount` ([#82](https://github.com/Roblox/roact/issues/82))
	* The old methods are still present as aliases, but will output a warning when used.
* Added `Roact.Change` for subscribing to `GetPropertyChangedSignal` ([#51](https://github.com/Roblox/roact/pull/51))
* Added the static lifecycle method `getDerivedStateFromProps` ([#57](https://github.com/Roblox/roact/pull/57))
* Allow canceling render by returning nil from setState callback ([#64](https://github.com/Roblox/roact/pull/64))
* Added `defaultProps` value on stateful components to define values for props that aren't specified ([#79](https://github.com/Roblox/roact/pull/79))
* Added `getElementTraceback` ([#81](https://github.com/Roblox/roact/issues/81), [#93](https://github.com/Roblox/roact/pull/93))
* Added `createRef` ([#70](https://github.com/Roblox/roact/issues/70), [#92](https://github.com/Roblox/roact/pull/92))
* Added a warning when an element changes type during reconciliation ([#88](https://github.com/Roblox/roact/issues/88), [#137](https://github.com/Roblox/roact/pull/137))
* Ref switching now occurs in one pass, which should fix edge cases where the result of a ref is `nil`, especially in property changed events ([#98](https://github.com/Roblox/roact/pull/98))
* `setState` can now be called inside `init` and `willUpdate`. Instead of triggering a new render, it will affect the currently scheduled one. ([#139](https://github.com/Roblox/roact/pull/139))
* Roll back changes that allowed `setState` to be called inside `willUpdate`, which created state update scenarios with difficult-to-determine behavior. ([#157](https://github.com/Roblox/roact/pull/157))
* By default, disable the warning for an element changing types during reconciliation ([#168](https://github.com/Roblox/roact/pull/168))

## 1.0.0 Prerelease 2 (March 22, 2018)
* Removed `is*Element` methods, this is unlikely to affect anyone ([#50](https://github.com/Roblox/roact/pull/50))
* Added new global configuration API for debug settings ([#46](https://github.com/Roblox/roact/pull/46))
* Added `Roact.reconcile`, which will be in the guide soon. It's useful for embedding Roact into existing projects! ([#44](https://github.com/Roblox/roact/pull/44))
* Added function variant of `setState` in preparation for async rendering ([#39](https://github.com/Roblox/roact/pull/39))
* Added `Roact.None` to allow removing values from state using `setState` ([#38](https://github.com/Roblox/roact/pull/38))
* `setState` will now throw errors if called at the wrong time ([#23](https://github.com/Roblox/roact/pull/23))
* Throw a nicer error when failing to set primitive properties ([#21](https://github.com/Roblox/roact/pull/21))
* If a bool is detected as a child of a component, it will be ignored, allowing for a shorter conditional rendering syntax! ([#15](https://github.com/Roblox/roact/pull/15))
* Error messages should make more sense in general
* Got rid of installer scripts in favor of regular model files

## 1.0.0 Prerelease 1 (December 1, 2017)
* Initial pre-release build