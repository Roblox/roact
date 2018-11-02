local Symbol = require(script.Parent.Symbol)

local createSignal = require(script.Parent.createSignal)

local Binding = {}

-- Used to indicate that an object is a binding
local BindingType = Symbol.named("BindingType")
-- Used to access a set of fields that are internal to Bindings
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

	return internalData.value
end

--[[
	Update a binding's value. This is only accessible by Roact.
]]
function Binding.update(binding, newValue)
	local internalData = binding[InternalData]

	internalData.value = newValue
	internalData.changeSignal:fire(newValue)
end

--[[
	Subscribe to a binding's change signal. This is only accessible by Roact.
]]
function Binding.subscribe(binding, handler)
	local internalData = binding[InternalData]

	return internalData.changeSignal:subscribe(handler)
end

--[[
	Determine whether the given input is a binding
]]
function Binding.is(object)
	return typeof(object) == "table" and object[BindingType] == true
end

--[[
	Create a new binding object with the given starting value. This
	function will be exposed to users of Roact.
]]
function Binding.create(initialValue)
	local binding = {
		[BindingType] = true,

		[InternalData] = {
			value = initialValue,
			changeSignal = createSignal(),
		},
	}

	setmetatable(binding, bindingPrototype)

	return binding
end

return Binding
