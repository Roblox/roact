--[[
	A ref is nothing more than a binding with a special field 'current'
	that maps to the getValue method of the binding
]]
local Binding = require(script.Parent.Binding)

local function createRef()
	local binding, _ = Binding.create(nil)

	getmetatable(binding).__index = function(self, key)
		-- TODO: Throw errors if attempting to access invalid fields
		if key == "current" then
			return self:getValue()
		end
	end

	return binding
end

return createRef