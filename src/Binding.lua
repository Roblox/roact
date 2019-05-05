local createSignal = require(script.Parent.createSignal)
local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local config = require(script.Parent.GlobalConfig).get()

--[[
	Default mapping function used for non-mapped bindings
]]
local function identity(value)
	return value
end

--[[
	Maps a table of bindings to their respective values. Used in Binding.join.
]]
local function mapBindingsToValues(bindings)
	local values = {}

	for key, binding in pairs(bindings) do
		values[key] = binding:getValue()
	end

	return values
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
		return the mapped value from our upstream binding(s).

		This allows us to avoid subscribing to our source until someone
		has subscribed to us, and avoid creating dangling connections.
	]]
	if internalData.upstreamBindingCount > 0 then
		return internalData.valueTransform(self:__getValueFromUpstreamBindings())
	end

	return internalData.value
end

--[[
	Creates a new binding from this one with the given mapping.
]]
function bindingPrototype:map(valueTransform)
	if config.typeChecks then
		assert(typeof(valueTransform) == "function", "Bad arg #1 to binding:map: expected function")
	end

	local binding = Binding.create(valueTransform(self:getValue()))
	local internalData = binding[InternalData]

	internalData.valueTransform = valueTransform

	internalData.upstreamBindings.source = self
	internalData.upstreamBindingCount = internalData.upstreamBindingCount + 1

	return binding
end

--[[
	Determines the final (not yet transformed) value from upstream bindings
]]
function bindingPrototype:__getValueFromUpstreamBindings()
	local internalData = self[InternalData]
	local newValue = mapBindingsToValues(internalData.upstreamBindings)

	if not internalData.isJoinedBinding then
		--[[
			If this is not a joined binding, there will always only be one upstream
			binding.

			To ensure that joined bindings with a single upstream binding always
			result in a table, we use the internal variable isJoinedBinding
		]]
		local _, value = next(newValue)
		newValue = value
	end

	return newValue
end

--[[
	Disconnects all connections to upstream bindings
]]
function bindingPrototype:__upstreamDisconnect()
	local internalData = self[InternalData]

	for _, disconnect in pairs(internalData.upstreamConnections) do
		disconnect()
	end
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
		we need to create subscriptions to our source bindings so that updates
		get passed along to us
	]]
	if internalData.upstreamBindingCount > 0 and internalData.subscriberCount == 0 then
		local function upstreamCallback()
			Binding.update(binding, binding:__getValueFromUpstreamBindings())
		end

		for _, upstreamBinding in pairs(internalData.upstreamBindings) do
			table.insert(internalData.upstreamConnections, Binding.subscribe(upstreamBinding, upstreamCallback))
		end
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
		if internalData.subscriberCount == 0 then
			binding:__upstreamDisconnect()
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
			isJoinedBinding = false,
			upstreamBindings = {},
			upstreamConnections = {},
			upstreamBindingCount = 0,
		},
	}

	setmetatable(binding, bindingPrototype)

	local setter = function(newValue)
		Binding.update(binding, newValue)
	end

	return binding, setter
end

--[[
	Creates a new binding which updates when any of the upstream bindings
	updates, which can be further mapped into any value. This function will
	be exposed to users of Roact.
]]
function Binding.join(bindings)
	local joinedBinding = Binding.create(mapBindingsToValues(bindings))
	local internalData = joinedBinding[InternalData]

	internalData.isJoinedBinding = true

	for key, binding in pairs(bindings) do
		internalData.upstreamBindings[key] = binding
		internalData.upstreamBindingCount = internalData.upstreamBindingCount + 1
	end

	return joinedBinding
end

return Binding