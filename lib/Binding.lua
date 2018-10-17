local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local createSignal = require(script.Parent.createSignal)

local Internal = {
	ChangeSignal = Symbol.named("ChangeSignal"),
	Value = Symbol.named("Value"),
}

local bindingMetatable = {
	__tostring = function(self)
		return ("RoactBinding(%s)"):format(tostring(self[Internal.Value]))
	end,
}

local Binding = {}

function Binding.create(initialValue)
	local binding = {
		[Type] = Type.Binding,
		[Internal.Value] = initialValue,
		[Internal.ChangeSignal] = createSignal(),
	}

	binding.getValue = function()
		return binding[Internal.Value]
	end

	binding.update = function(newValue)
		binding[Internal.Value] = newValue
		binding[Internal.ChangeSignal]:fire(newValue)
	end

	setmetatable(binding, bindingMetatable)

	return binding
end

function Binding.subscribe(binding, updateHandler)
	return binding[Internal.ChangeSignal]:subscribe(updateHandler)
end

return Binding