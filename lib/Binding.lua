local Type = require(script.Parent.Type)

local createSignal = require(script.Parent.createSignal)

--[[
	Default mapping function used for non-mapped bindings
]]
local function mapIdentity(value)
	return value
end

local Binding = {}
local BindingInternal = {}
BindingInternal.__index = BindingInternal
BindingInternal.__tostring = function(self)
	return ("RoactBinding(%s)"):format(tostring(self._value))
end

--[[
	Get the current value from a binding
]]
function BindingInternal:getValue()
	--[[
		If our source is another binding but we're not subscribed, we'll
		manually update ourselves before returning a value.

		This allows us to avoid subscribing to our source until someone
		has subscribed to us, and avoid creating dangling connections
	]]
	if Type.of(self._source) == Type.Binding and self._disconnectSource == nil then
		Binding.update(self, self._source:getValue())
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

--[[
	Update a binding's value
]]
function Binding.update(binding, newValue)
	newValue = binding._mapFunc(newValue)

	binding._value = newValue
	binding._changeSignal:fire(newValue)
end

--[[
	Subscribe to a binding's change signal
]]
function Binding.subscribe(binding, handler)
	--[[
		If this binding is mapped to another and does not have any subscribers,
		we need to create a subscription to our source binding so that updates
		get passed along to us
	]]
	if Type.of(binding._source) == Type.Binding and binding._subCount == 0 then
		binding._disconnectSource = Binding.subscribe(binding._source, function(value)
			Binding.update(binding, value)
		end)
	end

	local disconnect = binding._changeSignal:subscribe(handler)
	binding._subCount = binding._subCount + 1

	--[[
		We wrap the disconnect function so that we can manage our subscriptions
		when the disconnect is triggered
	]]
	return function()
		disconnect()
		binding._subCount = binding._subCount - 1

		--[[
			If our subscribers count drops to 0, we can safely unsubscribe from
			our source binding
		]]
		if binding._subCount == 0 and binding._disconnectSource ~= nil then
			binding._disconnectSource()
			binding._disconnectSource = nil
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

		_value = initialValue,
		_changeSignal = createSignal(),
		_mapFunc = mapIdentity,
		_subCount = 0,
	}

	setmetatable(binding, BindingInternal)

	local updater = function(newValue)
		Binding.update(binding, newValue)
	end

	return binding, updater
end

return Binding
