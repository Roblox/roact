# Roact Changelog

## Current `master` branch
* Added `Roact.Change` for subscribing to `GetPropertyChangedSignal` ([#51](https://github.com/Roblox/roact/pull/51))
* Added the static lifecycle method `getDerivedStateFromProps` ([#57](https://github.com/Roblox/roact/pull/57))

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