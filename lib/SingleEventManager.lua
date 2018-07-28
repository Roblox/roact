--[[
	An interface to have one event listener at a time on an event.

	One listener can be registered per SingleEventManager/Instance/Event triple.

	For example:

		myManager:connect(myPart, "Touched", touchedListener)
		myManager:connect(myPart, "Touched", otherTouchedListener)

	If myPart is touched, only `otherTouchedListener` will fire, because the
	first listener was disconnected during the second connect call.

	The hooks provided by SingleEventManager pass the associated Roblox object
	as the first parameter to the callback. This differs from normal
	Roblox events.

	SingleEventManager's public methods operate in terms of instances and string
	keys, differentiating between regular events and property changed signals
	by calling different methods.

	In the internal implementation, everything is handled via indexing by
	instances and event objects themselves. This allows the code to use the same
	structures for both kinds of instance event.
]]

local SingleEventManager = {}

SingleEventManager.__index = SingleEventManager

--[[
	Constructs a `Hook`, which is a bundle containing a method that can be
	updated, as well as the signal connection.
]]
local function createHook(instance, event, method)
	local hook = {
		method = method,
	}

	hook.connection = event:Connect(function(...)
		hook.method(instance, ...)
	end)

	return hook
end

function SingleEventManager.new()
	local self = {
		-- Map<Instance, Map<Event, Hook>>
		_hooks = {},
	}

	setmetatable(self, SingleEventManager)

	return self
end

function SingleEventManager:connect(instance, key, method)
	self:_connectInternal(instance, instance[key], key, method)
end

function SingleEventManager:connectProperty(instance, key, method)
	self:_connectInternal(instance, instance:GetPropertyChangedSignal(key), "Property:" .. key, method)
end

--[[
	Disconnects the hook attached to the event named `key` on the given
	`instance` if there is one, otherwise does nothing.

	Note that `key` must identify a valid property on `instance`, or this method
	will throw.
]]
function SingleEventManager:disconnect(instance, key)
	self:_disconnectInternal(instance, key)
end

--[[
	Disconnects the hook attached to the property changed signal on `instance`
	with the name `key` if there is one, otherwise does nothing.

	Note that `key` must identify a valid property on `instance`, or this method
	will throw.
]]
function SingleEventManager:disconnectProperty(instance, key)
	self:_disconnectInternal(instance, "Property:" .. key)
end

--[[
	Disconnects any hooks managed by SingleEventManager associated with
	`instance`.

	Calling disconnectAll with an untracked instance won't do anything.
]]
function SingleEventManager:disconnectAll(instance)
	local instanceHooks = self._hooks[instance]

	if instanceHooks == nil then
		return
	end

	for _, hook in pairs(instanceHooks) do
		hook.connection:Disconnect()
	end

	self._hooks[instance] = nil
end

--[[
	Creates a hook using the given event and method and associates it with the
	given instance.

	Generally, `event` should directly associated with `instance`, but that's
	unchecked in this code.
]]
function SingleEventManager:_connectInternal(instance, event, key, method)
	local instanceHooks = self._hooks[instance]

	if instanceHooks == nil then
		instanceHooks = {}
		self._hooks[instance] = instanceHooks
	end

	local existingHook = instanceHooks[key]

	if existingHook ~= nil then
		existingHook.method = method
	else
		instanceHooks[key] = createHook(instance, event, method)
	end
end

--[[
	Disconnects a hook associated with the given instance and event if it's
	present, otherwise does nothing.
]]
function SingleEventManager:_disconnectInternal(instance, key)
	local instanceHooks = self._hooks[instance]

	if instanceHooks == nil then
		return
	end

	local hook = instanceHooks[key]

	if hook == nil then
		return
	end

	hook.connection:Disconnect()
	instanceHooks[key] = nil

	-- If there are no hooks left for this instance, we don't need this record.
	if next(instanceHooks) == nil then
		self._hooks[instance] = nil
	end
end

return SingleEventManager
