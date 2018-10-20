local Type = require(script.Parent.Type)

local createSignal = require(script.Parent.createSignal)

<<<<<<< HEAD
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

=======
>>>>>>> Simplify, but remove privacy. Will try to reintroduced more sanely
local Binding = {}
local BindingInternal = {}
BindingInternal.__index = BindingInternal
BindingInternal.__tostring = function(self)
	return ("RoactBinding(%s)"):format(tostring(self._value))
end

function BindingInternal:_update(newValue)
	newValue = self._mapFunc(newValue)

	self._value = newValue
	self._changeSignal:fire(newValue)
end

function BindingInternal:_subscribe(handler)
		--[[
			If this binding is mapped to another and does not have any subscribers,
			we need to create a subscription to our source binding so that updates
			get passed along to us
		]]
		if Type.of(self._source) == Type.Binding and self._subCount == 0 then
			self._disconnectSource = self._source:_subscribe(function(value)
				self:_update(value)
			end)
		end

		local disconnect = self._changeSignal:subscribe(handler)
		self._subCount = self._subCount + 1

		--[[
			We wrap the disconnect function so that we can manage our subscriptions
			when the disconnect is triggered
		]]
		return function()
			disconnect()
			self._subCount = self._subCount - 1

			--[[
				If our subscribers count drops to 0, we can safely unsubscribe from
				our source binding
			]]
			if self._subCount == 0 and self._disconnectSource ~= nil then
				self._disconnectSource()
				self._disconnectSource = nil
			end
		end
end

function BindingInternal:getValue()
	--[[
		If our source is another binding but we're not subscribed, we'll
		manually update ourselves before returning a value.

		This allows us to avoid subscribing to our source until someone
		has subscribed to us, and avoid creating dangling connections
	]]
	if Type.of(self._source) == Type.Binding and self._disconnectSource == nil then
		self:_update(self._source:getValue())
	end

	return self._value
end

--[[
	Creates a new binding from this one with the given mapping.
]]
function BindingInternal:map(mapFunc)
	local binding = Binding.create(mapFunc(self:getValue()))

	binding._mapFunc = mapFunc
	binding._source = self

	return binding
end

local function noMap(value)
	return value
end

--[[
	Create a new binding object with the given starting value. This
	function will be exposed to users of Roact.
]]
function Binding.create(initialValue)
	local binding = {
		[Type] = Type.Binding,

		_value = initialValue,
		_changeSignal = createSignal(),
		_mapFunc = noMap,
		_subCount = 0,
	}

	setmetatable(binding, BindingInternal)

	local updater = function(newValue)
		binding:_update(newValue)
	end

	return binding, updater
end

--[[
	Invoke a binding's internal update method. Used by Roact, but
	not exposed in Roact's public interface.
]]
function Binding.update(binding, newValue)
	return binding:_update(newValue)
end

--[[
	Invoke a binding's internal subscribe method. Used by Roact, but
	not exposed in Roact's public interface.
]]
function Binding.subscribe(binding, handler)
	return binding:_subscribe(handler)
end

return Binding
