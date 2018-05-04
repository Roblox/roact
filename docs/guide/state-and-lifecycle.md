# State and Lifecycle
In the previous section, we talked about using components to create reusable chunks of state, and introduced *functional* and *stateful* components.

Stateful components do everything that functional components do, but have the addition of mutable *state* and *lifecycle methods*.

## State

!!! info
	This section is incomplete!

## Lifecycle Methods
Stateful components can provide methods to Roact that are called when certain things happen to a component instance.

Lifecycle methods are a great place to send off network requests, measure UI ([with the help of refs](/advanced/refs)), wrap non-Roact components, and produce other side-effects.

<div align="center">
	<a href="/images/lifecycle.svg">
		<img src="/images/lifecycle.svg" alt="Diagram of Roact Lifecycle" />
	</a>
</div>

## Incrementing Counter, Part Three
Building on the previous two examples, we can expand the incrementing counter to move the counter state and loop inside Roact, and use `setState` to trigger a re-render instead of `Roact.reconcile`.

Generally, this ticking clock demonstrates how many stateful components are structured in Roact.

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Roact = require(ReplicatedStorage.Roact)

local Clock = Roact.Component:extend("Clock")

function Clock:init()
	-- In init, you should assign to 'state' directly.
	-- Use this opportunity to set any initial values.
	self.state = {
		currentTime = 0
	}
end

-- This render function is almost completely unchanged from the first example.
function Clock:render()
	-- As a convention, we'll pull currentTime out of state right away.
	local currentTime = self.state.currentTime

	return Roact.createElement("ScreenGui", {}, {
		TimeLabel = Roact.createElement("TextLabel", {
			Size = UDim2.new(1, 0, 1, 0),
			Text = "Time Elapsed: " .. currentTime
		})
	})
end

-- Set up our loop in didMount, so that it starts running when our
-- component is created.
function Clock:didMount()
	-- Set a value that we can change later to stop our loop
	self.running = true

	-- We don't want to block the main thread, so we spawn a new one!
	spawn(function()
		while self.running do
			-- Because we depend on the previous state, we use the function
			-- variant of setState. This will matter more when Roact gets
			-- asynchronous rendering!
			self:setState(function(state)
				return {
					currentTime = state.currentTime + 1
				}
			end)

			wait(1)
		end
	end)
end

-- Stop the loop in willUnmount, so that our loop terminates when the
-- component is destroyed.
function Clock:willUnmount()
	self.running = false
end

local PlayerGui = Players.LocalPlayer.PlayerGui

-- Create our UI, which now runs on its own!
local handle = Roact.reify(Roact.createElement(Clock), PlayerGui, "Clock UI")

-- Later, we can destroy our UI and disconnect everything correctly.
wait(10)
Roact.teardown(handle)
```