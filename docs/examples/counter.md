# Stateful Counter
In [*Hello, Roact!*](hello-roact.html), two simple ways of creating a static component were shown off.

Of course, Roact wouldn't be useful if state didn't change, so we're going to build a component that shows the number of seconds since it was created.

```lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Roact)

-- A functional component to render the current tick.
-- This component has no local state. Most components are like this!
local function TickLabel(props)
	local value = props.value

	return Roact.createElement("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Text = ("Current tick is %d!"):format(value),
	})
end

local App = Roact.Component:extend("App")

function App:init()
	-- State that cannot affect rendering can exist directly on the instance.
	-- This variable is used to kill the timer loop when the component ends.
	self.running = false

	-- State that changes rendering must exist in `state`!
	-- You can only directly assign to `state` in the constructor.
	self.state = {
		count = 0
	}
end

function App:render()
	return Roact.createElement("ScreenGui", {
	}, {
		-- We can render our own components just like Roblox primitives
		Count = Roact.createElement(TickLabel, {
			value = self.state.count,
		}),
	})
end

function App:didMount()
	-- Use 'didMount' to be notified when a component instance is created

	spawn(function()
		self.running = true

		while self.running do
			-- Use 'setState' to update the component and patch the current
			-- state with new properties.
			-- Don't set `state` directly!
			self:setState({
				count = self.state.count + 1
			})

			wait(1)
		end
	end)
end

function App:willUnmount()
	-- 'willUnmount' notifies you when your component is about to be removed.
	-- Do any cleanup here, like terminating a loop!
	self.running = false
end

local element = Roact.createElement(App)

Roact.reify(element, Players.LocalPlayer.PlayerGui, "StatefulCounter")
```