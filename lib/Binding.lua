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
	local self = {
		[Type] = Type.Binding,
		[Internal.Value] = initialValue,
		[Internal.ChangeSignal] = createSignal(),
	}

	self.getValue = function()
		return self[Internal.Value]
	end

	setmetatable(self, bindingMetatable)

	local updater = function(newValue)
		self[Internal.Value] = newValue
		self[Internal.ChangeSignal]:fire(newValue)
	end

	return self, updater
end

function Binding.subscribe(binding, updateHandler)
	return binding[Internal.ChangeSignal]:subscribe(updateHandler)
end

return Binding