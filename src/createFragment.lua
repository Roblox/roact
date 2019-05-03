local Type = require(script.Parent.Type)

local function createFragment(elements)
	return {
		[Type] = Type.Fragment,
		elements = elements,
	}
end

return createFragment