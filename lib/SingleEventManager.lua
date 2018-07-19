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

local function disconnectAllForInstance(hooks, instance)
	local instanceHooks = hooks[instance]

	if instanceHooks == nil then
		return
	end

	for _, hook in pairs(instanceHooks) do
		hook.connection:Disconnect()
	end

	hooks[instance] = nil
end

local function disconnectEventForInstance(hooks, instance, event)
	local instanceHooks = hooks[instance]

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
		hooks[instance] = nil
	end
end

local function connect(hooks, instance, event, method)
	local instanceHooks = hooks[instance]

	if instanceHooks == nil then
		instanceHooks = {}
		hooks[instance] = instanceHooks
	end

	local existingHook = instanceHooks[event]

	if existingHook ~= nil then
		existingHook.method = method
	else
		instanceHooks[event] = createHook(instance, event, method)
	end
end

function SingleEventManager.new()
	local self = {}

	self._eventHooks = {}
	self._propertyHooks = {}

	setmetatable(self, SingleEventManager)

	return self
end

function SingleEventManager:connect(instance, key, method)
	connect(self._eventHooks, instance, instance[key], method)
end

function SingleEventManager:connectProperty(instance, key, method)
	connect(self._propertyHooks, instance, instance:GetPropertyChangedSignal(key), method)
end

function SingleEventManager:disconnect(instance, key)
	disconnectEventForInstance(self._eventHooks, instance, instance[key])
end

function SingleEventManager:disconnectProperty(instance, key)
	disconnectEventForInstance(self._propertyHooks, instance, instance:GetPropertyChangedSignal(key))
end

function SingleEventManager:disconnectAll(instance)
	disconnectAllForInstance(self._eventHooks, instance)
	disconnectAllForInstance(self._propertyHooks, instance)
end

return SingleEventManager
