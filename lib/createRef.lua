--[[
	A ref is nothing more than a binding with a special field 'current'
	that maps to the getValue method of the binding
]]
local Binding = require(script.Parent.Binding)

local function createRef()
	local binding = Binding.create(nil)

	local ref = {}

	--[[
		A ref is just redirected to a binding via metatable
	]]
	setmetatable(ref, {
		__index = function(self, key)
			if key == "current" then
				return binding:getValue()
			else
				return binding[key]
			end
		end,
		__newindex = function(self, key, value)
			if key == "current" then
				--[[
					While previously refs did not have any special behavior if users assigned to
					current, we'll have it trigger normal updating, so that it functions as a getter
					AND a setter. This shouldn't change any previous behavior with refs, but will
					make First-Class Refs respond to user assignments to 'current'.

					Assigning to current is of course still highly discouraged!
				]]
				Binding.update(binding, value)
			else
				binding[key] = value
			end
		end,
		__tostring = function(self)
			return ("RoactRef(%s)"):format(tostring(binding:getValue()))
		end,
	})

	return ref
end

return createRef