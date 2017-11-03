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

local function createHook(rbx, key, method)
	local hook = {
		method = method,
		connection = rbx[key]:Connect(function(...)
			method(rbx, ...)
		end)
	}

	return hook
end

function SingleEventManager.new()
	local self = {}

	self._hookCache = {}

	setmetatable(self, SingleEventManager)

	return self
end

function SingleEventManager:connect(rbx, key, method)
	local rbxHooks = self._hookCache[rbx]

	if rbxHooks then
		local existingHook = rbxHooks[key]

		if existingHook then
			if existingHook.method == method then
				return
			end

			existingHook.connection:Disconnect()
		end

		rbxHooks[key] = createHook(rbx, key, method)
	else
		rbxHooks = {}
		rbxHooks[key] = createHook(rbx, key, method)

		self._hookCache[rbx] = rbxHooks
	end
end

function SingleEventManager:disconnect(rbx, key)
	local rbxHooks = self._hookCache[rbx]

	if not rbxHooks then
		return
	end

	local existingHook = rbxHooks[key]

	if not existingHook then
		return
	end

	existingHook.connection:Disconnect()
	rbxHooks[key] = nil

	if next(rbxHooks) == nil then
		self._hookCache[rbx] = nil
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