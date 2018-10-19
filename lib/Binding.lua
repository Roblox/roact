local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local createSignal = require(script.Parent.createSignal)

--[[
	Markers for fields and methods that are hidden from external users
]]
local Internal = {
	value = Symbol.named("value"),

	update = Symbol.named("update"),
	subscribe = Symbol.named("subscribe"),
}

local bindingMetatable = {
	__tostring = function(self)
		return ("RoactBinding(%s)"):format(tostring(self[Internal.value]))
	end,
}

local Binding = {}

--[[
	Create a new binding object with the given starting value. This
	function will be exposed to users of Roact.
]]
function Binding.create(initialValue)
	local binding = Binding.createFromSource(initialValue, function(value)
		return value
	end)

	local updater = function(newValue)
		binding[Internal.update](binding, newValue)
	end

	return binding, updater
end

--[[
	Creates a new binding from the given source and with the given mapping.

	The source can either be a starting value or another Binding object,
	which is useful for mapping a binding onto another binding
]]
function Binding.createFromSource(source, mapFunc)
	local initialValue = source
	if Type.of(source) == Type.Binding then
		initialValue = source:getValue()
	end

	local subCount = 0
	local disconnectSource = nil
	local changeSignal = createSignal()

	local binding = {
		[Type] = Type.Binding,

		[Internal.value] = mapFunc(initialValue),
	}

	binding[Internal.update] = function(self, newValue)
		assert(Type.of(newValue) ~= Type.Binding, "Cannot bind value of type Binding")

		newValue = mapFunc(newValue)

		self[Internal.value] = newValue
		changeSignal:fire(newValue)
	end

	binding[Internal.subscribe] = function(self, handler)
		--[[
			If this binding is mapped to another and does not have any subscribers,
			we need to create a subscription to our source binding so that updates
			get passed along to us
		]]
		if Type.of(source) == Type.Binding and subCount == 0 then
			disconnectSource = source[Internal.subscribe](source, function(value)
				self[Internal.update](self, value)
			end)
		end

		local disconnect = changeSignal:subscribe(handler)
		subCount = subCount + 1

		return function()
			disconnect()
			subCount = subCount - 1

			--[[
				If our subscribers count drops to 0, we can safely unsubscribe from
				our source binding
			]]
			if subCount == 0 and disconnectSource ~= nil then
				disconnectSource()
				disconnectSource = nil
			end
		end
	end

	function binding:getValue()
		--[[
			If our source is another binding but we're not subscribed, we'll
			manually update ourselves before returning a value.

			This allows us to avoid subscribing to our source until someone
			has subscribed to us, and avoid creating dangling connections
		]]
		if Type.of(source) == Type.Binding and disconnectSource == nil then
			self[Internal.update](self, source:getValue())
		end

		return self[Internal.value]
	end

	function binding:map(newMapFunc)
		return Binding.createFromSource(self, newMapFunc)
	end

	setmetatable(binding, bindingMetatable)

	return binding
end

--[[
	Invoke a binding's internal update method. Used by Roact, but
	not exposed in Roact's public interface.
]]
function Binding.update(binding, newValue)
	return binding[Internal.update](binding, newValue)
end

--[[
	Invoke a binding's internal subscribe method. Used by Roact, but
	not exposed in Roact's public interface.
]]
function Binding.subscribe(binding, handler)
	return binding[Internal.subscribe](binding, handler)
end

return Binding
