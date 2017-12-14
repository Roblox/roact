# Usage with Rodux
React and [Rodux](https://github.com/Roblox/Rodux) get along very well with use of [RoactRodux](https://github.com/Roblox/RoactRodux).

To connect to the store in a component, use `RoactRodux.connect` to generate a wrapper component:

```lua
-- Write a regular component first
local function UserCard(props)
	local name = props.name

	return Roact.createElement("TextLabel", {
		Text = ("Hello, %s!"):format(name)
	})
end

-- Generate a specialized version of this component that depends on the store
local CurrentUserCard = RoactRodux.connect(function(store)
	local state = store:getState()

	-- The return value of this function is passed as props to UserCard
	-- Any props passed to CurrentUserCard will also be passed.
	return {
		name = state.currentUser.name
	}
end)(UserCard)
```

Then, wrap the root component of the app (which doesn't need to connect to the Rodux store) by making it a child of a ReactRodux `StoreProvider`:

```lua
-- Our app just displays the current user's name
local function App(props)
	return Roact.createElement(CurrentUserCard)
end

-- Create our store like normal
local store = Rodux.Store.new(reducer)

-- Instead of creating the App directly, we create a StoreProvider above it
-- We have to pass `store` as a prop to tell StoreProvider what store to connect to!
local element = Roact.createElement(RoactRodux.StoreProvider, {
	store = store
}, {
	App = Roact.createElement(App)
})
```

For a complete example, check out the [Roact with Rodux example](/examples/roact-rodux.md).