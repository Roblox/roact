--[[
	This is a simple signal implementation that has a dead-simple API.

		local signal = createSignal()

		local disconnect = signal:subscribe(function(foo)
			print("Cool foo:", foo)
		end)

		signal:fire("something")

		disconnect()
]]

local DEBUG_SIGNAL = true
local debug_globalSubs = 0

local function addToMap(map, addKey, addValue)
	local new = {}

	for key, value in pairs(map) do
		new[key] = value
	end

	new[addKey] = addValue

	if DEBUG_SIGNAL then
		debug_globalSubs = debug_globalSubs + 1
		print("Signal subscriptions:", debug_globalSubs)
	end

	return new
end

local function removeFromMap(map, removeKey)
	local new = {}

	for key, value in pairs(map) do
		if key ~= removeKey then
			new[key] = value
		end
	end

	if DEBUG_SIGNAL then
		debug_globalSubs = debug_globalSubs - 1
		print("Signal subscriptions:", debug_globalSubs)
	end

	return new
end

local function createSignal()
	local connections = {}

	local function subscribe(self, callback)
		assert(typeof(callback) == "function", "Can only subscribe to signals with a function.")

		local connection = {
			callback = callback,
		}

		connections = addToMap(connections, callback, connection)

		local function disconnect()
			assert(not connection.disconnected, "Listeners can only be disconnected once.")

			connection.disconnected = true
			connections = removeFromMap(connections, callback)

			--[[
				We return nil here to make it easier to clear connections and nil out their references:

					local disconnect = mapOfConnections[key]
					mapOfConnections[key] = disconnect()
			]]
			return nil
		end

		return disconnect
	end

	local function fire(self, ...)
		for callback, connection in pairs(connections) do
			if not connection.disconnected then
				callback(...)
			end
		end
	end

	return {
		subscribe = subscribe,
		fire = fire,
	}
end

return createSignal