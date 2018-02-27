# What is Roact?
Roact is a *declarative* UI library for Roblox.

What does this mean exactly?

## A Simple Problem

Normally, when you build a UI in Roblox (or a lot of systems), you create some objects and set some properties on them:

```lua
local userName = "UristMcSparks"

local userLabel = Instance.new("TextLabel")
userLabel.Text = userName

-- The text is as red as it is long
userLabel.TextColor3 = Color3.fromRGB(#userName, 0, 0)
```

And then when you have some sort of state change, you just change your object based on your data:

```lua
userName = "OnlyTwentyCharacters"

userLabel.Text = userName
userLabel.TextColor3 = Color3.fromRGB(#userName, 0, 255)
```

Now we have to remember to update `userLabel` every time `userName` changes! Augh!

More than that, you have to think about *creating* and *updating* your object separately. The code lives in two places, and if we change one, we can forget to the change the other.

Let's focus on solving the second problem.

One possibility is that we just throw away `userLabel` every time there's an update, and have users call a new function, `setUserName`, to update it.

```lua
local function makeLabel(name)
	local label = Instance.new("TextLabel")
	label.Text = name
	label.TextColor3 = Color3.fromRGB(#name, 0, 0)

	return label
end

local userLabel = makeLabel("UristMcSparks")

local function setUserName(name)
	userLabel:Destroy()
	userLabel = makeLabel(name)
end
```

This functions in our simple case pretty well. There's no chance that we'll mess up the *change* part of our UI, but we gain some new problems!

We're creating a lot of garbage; you can't get away with this for a big UI. All we *really* wanted to do was change a couple of properties, not make a whole new object.

When building the new Lua chat on iOS, this is the approach that was taken for most *small* components. It introduced some performance problems, but did make the code drastically simpler in many cases.

This is where Roact helps. It lets you write code similar to the `makeLabel` function, without having any of the downsides:

```lua
local function UserLabel(props)
	local name = props.name

	return Roact.createElement("TextLabel", {
		Text = name,
		TextColor3 = Color3.fromRGB(#name, 0, 0),
	})
end
```

What we've done here is create a *functional component*. It stands in for the `makeLabel` function above.

From here, you can hook `UserLabel` up to Rodux and it will automatically stay in sync with whatever your user label is, without creating a bunch of junk!

The code to do that hookup isn't that bad, either:

```lua
local CurrentUserLabel = RoactRodux.connect(function(store)
	-- We get access to a Rodux store and return props for our component
	local state = store:GetState()

	return {
		name = state.currentUser,
	}
end)
```

## A Less Simple Problem: Lists

As a more complicated example, what about trying to show a list of users?

Without any fancy libraries:

```lua
local users = {"Alice", "Bob", "Carol", "Dave", "Eric", "Freddy", "Gale", "Havve"}

local function makeLabels(users)
	local container = Instance.new("Frame")

	-- Lay our users out in a list
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = container

	for index, user in ipairs(users) do
		local userLabel = Instance.new("TextLabel")
		userLabel.Text = user
		userLabel.LayoutOrder = index
		userLabel.Parent = container
	end

	return container
end

local function updateUsers(users)
	-- uh oh...
end
```

Now we run into a roadblock. How do we update the UI with a new list of users?

We could throw away the entire UI like in the previous example, but even with just 8 users, that's a lot of waste.

In Lua chat for iOS, we hit this problem but had dozens to *hundreds* of entries in our lists. Messages could be inserted or changed anywhere in the list, so we had to handle every possible mutation gracefully and generically.

In that case, we wrote code to traverse the old and new `users` lists, comparing values and order, manually replacing elements where things differed.

Roact can give us a hand with this problem:

```lua
local function UserLabels(props)
	local users = props.users

	local children = {}

	for index, user in ipairs(users) do
		local userElement = Roact.createElement("TextLabel", {
			Text = user,
			LayoutOrder = index,
		})

		children["User-" .. user] = userElement
	end

	children.Layout = Roact.createElement("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
	})

	return Roact.createElement("Frame", {}, children)
end
```

That's it. Roact will deal with any changes to the list of users, and there's no chance that the list will be out of sync with the data that Roact was given.