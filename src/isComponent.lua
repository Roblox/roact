local Portal = require(script.Parent.Portal)
local Type = require(script.Parent.Type)

-- Returns true if the provided object can be used by Roact.createElement
return function(value)
	local valueType = type(value)

	local isComponentClass = Type.of(value) == Type.StatefulComponentClass
	local isValidFunctionComponentType = valueType == "function"
	local isValidHostType = valueType == "string"
	local isPortal = value == Portal

	return isComponentClass or isValidFunctionComponentType or isValidHostType or isPortal
end