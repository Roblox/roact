local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local createSignal = require(script.Parent.createSignal)

--[[
	Default mapping function used for non-mapped bindings
]]
local function identity(value)
	return value
end

local Binding = {}

--[[
	Set of keys for fields that are internal to Bindings
]]
local InternalData = Symbol.named("InternalData")

local bindingPrototype = {}
bindingPrototype.__index = bindingPrototype
bindingPrototype.__tostring = function(self)
	return ("RoactBinding(%s)"):format(tostring(self[InternalData].value))
end

--[[
	Get the current value from a binding
]]
function bindingPrototype:getValue()
	local internalData = self[InternalData]

	--[[
		If our source is another binding but we're not subscribed, we'll
		return the mapped value from our upstream binding.

		This allows us to avoid subscribing to our source until someone
		has subscribed to us, and avoid creating dangling connections.
	]]
	if internalData.upstreamBinding ~= nil and internalData.upstreamDisconnect == nil then
		return internalData.valueTransform(internalData.upstreamBinding:getValue())
	end

	return internalData.value
end

--[[
	Creates a new binding from this one with the given mapping.
]]
function bindingPrototype:map(valueTransform)
	local binding = Binding.create(valueTransform(self:getValue()))

	binding[InternalData].valueTransform = valueTransform
	binding[InternalData].upstreamBinding = self

	return binding
end

--[[
	Update a binding's value. This is only accessible by Roact.
]]
function Binding.update(binding, newValue)
	local internalData = binding[InternalData]

	newValue = internalData.valueTransform(newValue)

	internalData.value = newValue
	internalData.changeSignal:fire(newValue)
end

--[[
	Subscribe to a binding's change signal. This is only accessible by Roact.
]]
function Binding.subscribe(binding, handler)
	local internalData = binding[InternalData]

	--[[
		If this binding is mapped to another and does not have any subscribers,
		we need to create a subscription to our source binding so that updates
		get passed along to us
	]]
	if internalData.upstreamBinding ~= nil and internalData.subscriberCount == 0 then
		internalData.upstreamDisconnect = Binding.subscribe(internalData.upstreamBinding, function(value)
			Binding.update(binding, value)
		end)
	end

	local disconnect = internalData.changeSignal:subscribe(handler)
	internalData.subscriberCount = internalData.subscriberCount + 1

	local disconnected = false

	--[[
		We wrap the disconnect function so that we can manage our subscriptions
		when the disconnect is triggered
	]]
	return function()
		if disconnected then
			return
		end

		disconnected = true
		disconnect()
		internalData.subscriberCount = internalData.subscriberCount - 1

		--[[
			If our subscribers count drops to 0, we can safely unsubscribe from
			our source binding
		]]
		if internalData.subscriberCount == 0 and internalData.upstreamDisconnect ~= nil then
			internalData.upstreamDisconnect()
			internalData.upstreamDisconnect = nil
		end
	end
end

--[[
	Create a new binding object with the given starting value. This
	function will be exposed to users of Roact.
]]
function Binding.create(initialValue)
	local binding = {
		[Type] = Type.Binding,

		[InternalData] = {
			value = initialValue,
			changeSignal = createSignal(),
			subscriberCount = 0,

			valueTransform = identity,
			upstreamBinding = nil,
			upstreamDisconnect = nil,
		},
	}

	setmetatable(binding, bindingPrototype)

	local setter = function(newValue)
		Binding.update(binding, newValue)
	end

	return binding, setter
end

return Binding