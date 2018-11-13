--[[
	A manager for a single host virtual node's connected events.
]]

local CHANGE_PREFIX = "Change."

local SingleEventManager = {}
SingleEventManager.SuspensionStatus = {
	-- No events are processed at all; they're silently discarded
	Disabled = 1,
	-- Events are stored in a queue; listeners are invoked when the manager is resumed
	Suspended = 2,
	-- Event listeners are invoked as the events fire
	Enabled = 3,
}

local SingleEventManagerPrototype = {}
SingleEventManagerPrototype.__index = SingleEventManagerPrototype

function SingleEventManager.new(instance)
	local self = setmetatable({
		-- The queue of suspended events
		_queue = {},
		-- All the event connections being managed
		-- Events are indexed by a string key
		_connections = {},
		-- All the listeners being managed
		-- These are stored distinctly from the connections
		-- Connections can have their listeners replaced at runtime
		_listeners = {},
		-- The suspension status of the manager
		-- Managers start disabled and are "resumed" after the initial render
		_state = SingleEventManager.SuspensionStatus.Disabled,
		_instance = instance,
	}, SingleEventManagerPrototype)

	return self
end

function SingleEventManagerPrototype:connectEvent(key, listener)
	self:_connect(key, self._instance[key], listener)
end

function SingleEventManagerPrototype:connectPropertyChange(key, listener)
	self:_connect(CHANGE_PREFIX..key, self._instance:GetPropertyChangedSignal(key), listener)
end

function SingleEventManagerPrototype:_connect(eventKey, event, listener)
	-- If the listener doesn't exist we can just disconnect the existing connection
	if listener == nil then
		if self._connections[eventKey] ~= nil then
			self._connections[eventKey]:Disconnect()
		end
	else
		if self._connections[eventKey] == nil then
			self._connections[eventKey] = event:Connect(function(...)
				if self._state == SingleEventManager.SuspensionStatus.Enabled then
					self._listeners[eventKey](self._instance, ...)
				elseif self._state == SingleEventManager.SuspensionStatus.Suspended then
					-- Store event key (so we know which listener to invoke), count of arguments (so unpack())
					-- doesn't freak out with nils), and finally the arguments themselves.
					table.insert(self._queue, { eventKey, select("#", ...), ... })
				end
			end)
		end

		self._listeners[eventKey] = listener
	end
end

function SingleEventManagerPrototype:suspend()
	self._state = SingleEventManager.SuspensionStatus.Suspended
end

function SingleEventManagerPrototype:resume()
	self._state = SingleEventManager.SuspensionStatus.Enabled

	for i = 1, #self._queue do
		local record = self._queue[i]
		local listener = self._listeners[record[1]]
		local count = record[2]
		listener(self._instance, unpack(record, 3))
	end

	self._queue = {}
end

return SingleEventManager
