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
]]

local SingleEventManager = {}

SingleEventManager.__index = SingleEventManager

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
	local self = {}

	self._hooks = {}

	setmetatable(self, SingleEventManager)

	return self
end

function SingleEventManager:_connectInternal(instance, event, method)
	local instanceHooks = self._hooks[instance]

	if instanceHooks == nil then
		instanceHooks = {}
		self._hooks[instance] = instanceHooks
	end

	local existingHook = instanceHooks[event]

	if existingHook ~= nil then
		existingHook.method = method
	else
		instanceHooks[event] = createHook(instance, event, method)
	end
end

function SingleEventManager:connect(instance, key, method)
	self:_connectInternal(instance, instance[key], method)
end

function SingleEventManager:connectProperty(instance, key, method)
	self:_connectInternal(instance, instance:GetPropertyChangedSignal(key), method)
end

function SingleEventManager:_disconnectInternal(instance, event)
	local instanceHooks = self._hooks[instance]

	if instanceHooks == nil then
		return
	end

	local hook = instanceHooks[event]

	if hook == nil then
		return
	end

	hook.connection:Disconnect()
	instanceHooks[event] = nil

	-- If there are no hooks left for this instance, we don't need this record.
	if next(instanceHooks) == nil then
		self._hooks[instance] = nil
	end
end

function SingleEventManager:disconnect(instance, key)
	self:_disconnectInternal(instance, instance[key])
end

function SingleEventManager:disconnectProperty(instance, key)
	self:_disconnectInternal(instance, instance:GetPropertyChangedSignal(key))
end

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

return SingleEventManager
