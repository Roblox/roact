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

local function createHook(rbx, event, method)
	local hook = {
		method = method,
	}

	hook.connection = event:Connect(function(...)
		hook.method(rbx, ...)
	end)

	return hook
end

function SingleEventManager.new()
	local self = {}

	self._eventHooks = {}
	self._propertyHooks = {}

	setmetatable(self, SingleEventManager)

	return self
end

function SingleEventManager:connect(rbx, key, method)
	local hooks = self._eventHooks[rbx]

	if hooks == nil then
		hooks = {}
		self._eventHooks[rbx] = hooks
	end

	local existingHook = hooks[key]

	if existingHook ~= nil then
		existingHook.method = method
	else
		hooks[key] = createHook(rbx, rbx[key], method)
	end
end

function SingleEventManager:connectProperty(rbx, key, method)
	local hooks = self._propertyHooks[key]

	if hooks == nil then
		hooks = {}
		self._propertyHooks[rbx] = hooks
	end

	local existingHook = hooks[key]

	if existingHook ~= nil then
		existingHook.method = method
	else
		hooks[key] = createHook(rbx, rbx:GetPropertyChangedSignal(key), method)
	end
end

function SingleEventManager:disconnect(rbx, key)
	local hooks = self._eventHooks[rbx]

	if hooks == nil then
		return
	end

	local existingHook = hooks[key]

	if existingHook == nil then
		return
	end

	existingHook.connection:Disconnect()
	hooks[key] = nil

	if next(hooks) == nil then
		self._eventHooks[rbx] = nil
	end
end

function SingleEventManager:disconnectProperty(rbx, key)
	local hooks = self._propertyHooks[rbx]

	if hooks == nil then
		return
	end

	local existingHook = hooks[key]

	if existingHook == nil then
		return
	end

	existingHook.connection:Disconnect()
	hooks[key] = nil

	if next(hooks) == nil then
		self._propertyHooks[rbx] = nil
	end
end

function SingleEventManager:disconnectAll(rbx)
	local rbxHooks = self._hookCache[rbx]

	if not rbxHooks then
		return
	end

	for _, hook in pairs(rbxHooks) do
		hook.connection:Disconnect()
	end

	self._hookCache[rbx] = nil
end

return SingleEventManager
