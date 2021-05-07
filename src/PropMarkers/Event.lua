--[[
	Index into `Event` to get a prop key for attaching to an event on a Roblox
	Instance.

	Example:

		Roact.createElement("TextButton", {
			Text = "Hello, world!",

			[Roact.Event.MouseButton1Click] = function(rbx)
				print("Clicked", rbx)
			end
		})
]]

local Type = require(script.Parent.Parent.Type)

local Event = {}

local eventMetatable = {
	__tostring = function(self)
		return string.format("RoactHostEvent(%s)", self.name)
	end,
}

setmetatable(Event, {
	__index = function(_, eventName)
		local event = {
			[Type] = Type.HostEvent,
			name = eventName,
		}

		setmetatable(event, eventMetatable)

		Event[eventName] = event

		return event
	end,
})

return Event
