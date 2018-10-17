--[[
	Provides an API for acquiring a reference to a reified object. This
	API is designed to mimic React 16.3's createRef API.

	See:
	* https://reactjs.org/docs/refs-and-the-dom.html
	* https://reactjs.org/blog/2018/03/29/react-v-16-3.html#createref-api
]]
local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)
local Binding = require(script.Parent.Binding)

local Internal = {
	Binding = Symbol.named("Binding"),
	Updater = Symbol.named("Updater"),
}

local refMetatable = {
	__tostring = function(self)
		return ("RoactRef(%s)"):format(tostring(self.current))
	end,

	-- Compatibility layer
	__index = function(self, key)
		if key == "current" then
			return self[Internal.Binding].getValue()
		end
	end,
}

local Ref = {}

function Ref.create()
	local binding, updater = Binding.create(nil)

	local ref = {
		[Type] = Type.Ref,
		[Internal.Binding] = binding,
		[Internal.Updater] = updater,
	}

	setmetatable(ref, refMetatable)

	return ref
end

function Ref.apply(ref, newRbx)
	if ref ~= nil then
		ref[Internal.Updater](newRbx)
	end
end

return Ref