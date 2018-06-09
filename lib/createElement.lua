local Core = require(script.Parent.Core)
local GlobalConfig = require(script.Parent.GlobalConfig)

--[[
	Creates a new Roact element of the given type.

	Does not create any concrete objects.
]]
local function createElement(elementType, element, children)
	element = element or {}

	if elementType then
		if element[Core.Type] then
			warn("element[Type] was defined but was overriden by createElement!")
		end

		element[Core.Type] = elementType
	end

	if children then
		if element[Core.Children] then
			warn("element[Children] was defined but was overridden by third parameter to createElement!")
		end

		element[Core.Children] = children
	end

	if GlobalConfig.getValue("elementTracing") then
		element[Core.Source] = ("\n%s\n"):format(debug.traceback())
	end

	return element
end

return createElement