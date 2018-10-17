local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local createSignal = require(script.Parent.createSignal)

local Internal = {
	changeSignal = Symbol.named("changeSignal"),
	value = Symbol.named("value"),
}

local bindingMetatable = {
	__tostring = function(self)
		return "RoactBinding"
	end,
}

local Binding = {}

function Binding.create(initialValue)
	local binding = {
		[Type] = Type.Binding,

		[Internal.value] = initialValue,
		[Internal.changeSignal] = createSignal(),
	}

	binding.getValue = function()
		return binding[Internal.value]
	end

	setmetatable(binding, bindingMetatable)

	local updater = function(newValue)
		binding[Internal.value] = newValue
		binding[Internal.changeSignal]:fire(newValue)
	end

	return binding, updater
end

function Binding.subscribe(binding, updateHandler)
	return binding[Internal.changeSignal]:subscribe(updateHandler)
end

return Binding