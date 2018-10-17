--[[
	Provides an API for acquiring a reference to a reified object. This
	API is designed to mimic React 16.3's createRef API.

	See:
	* https://reactjs.org/docs/refs-and-the-dom.html
	* https://reactjs.org/blog/2018/03/29/react-v-16-3.html#createref-api
]]
local Binding = require(script.Parent.Binding)
local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local Internal = {
	binding = Symbol.named("binding"),
	updater = Symbol.named("updater"),
}

local refMetatable = {
	__tostring = function(self)
		return ("RoactRef(%s)"):format(tostring(self.current))
	end,

	-- Compatibility layer to extract value from binding
	__index = function(self, key)
		if key == "current" then
			return self[Internal.binding].getValue()
		end
	end,
}

local Ref = {}

function Ref.create()
	local binding, updater = Binding.create(nil)

	local ref = {
		[Type] = Type.Ref,
		[Internal.binding] = binding,
		[Internal.updater] = updater,
	}

	setmetatable(ref, refMetatable)

	return ref
end

function Ref.getBinding(ref)
	return ref[Internal.binding]
end

--[[
	Update the rbx value in a given ref
]]
function Ref.apply(ref, newRbx)
	if ref ~= nil then
		ref[Internal.updater](newRbx)
	end
end

return Ref