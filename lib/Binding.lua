local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local createSignal = require(script.Parent.createSignal)

--[[
	Default mapping function used for non-mapped bindings
]]
local function mapIdentity(value)
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
	if internalData.upstreamBinding ~= nil and internalData.disconnectSource == nil then
		return internalData.mapFunc(internalData.upstreamBinding:getValue())
	end

	return internalData.value
end

--[[
	Creates a new binding from this one with the given mapping.
]]
function bindingPrototype:map(mapFunc)
	local binding = Binding.create(mapFunc(self:getValue()))

	binding[InternalData].mapFunc = mapFunc
	binding[InternalData].upstreamBinding = self

	return binding
end

--[[
	Update a binding's value. This is only accessible by Roact.
]]
function Binding.update(binding, newValue)
	local internalData = binding[InternalData]

	newValue = internalData.mapFunc(newValue)

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
	if internalData.upstreamBinding ~= nil and internalData.subCount == 0 then
		internalData.disconnectSource = Binding.subscribe(internalData.upstreamBinding, function(value)
			Binding.update(binding, value)
		end)
	end

	local disconnect = internalData.changeSignal:subscribe(handler)
	internalData.subCount = internalData.subCount + 1

	--[[
		We wrap the disconnect function so that we can manage our subscriptions
		when the disconnect is triggered
	]]
	return function()
		disconnect()
		internalData.subCount = internalData.subCount - 1

		--[[
			If our subscribers count drops to 0, we can safely unsubscribe from
			our source binding
		]]
		if internalData.subCount == 0 and internalData.disconnectSource ~= nil then
			internalData.disconnectSource()
			internalData.disconnectSource = nil
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
			subCount = 0,

			mapFunc = mapIdentity,
			upstreamBinding = nil,
			disconnectSource = nil,
		},
	}

	setmetatable(binding, bindingPrototype)

	local updater = function(newValue)
		Binding.update(binding, newValue)
	end

	return binding, updater
end

return Binding
