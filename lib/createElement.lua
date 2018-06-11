local Core = require(script.Parent.Core)
local GlobalConfig = require(script.Parent.GlobalConfig)

--[[
	Creates a new Roact element of the given type.

	Does not create any concrete objects.
]]
local function createElement(elementType, props, children)
	if elementType == nil then
		error(("Expected elementType as an argument to createElement!"), 2)
	end

	props = props or {}

	if children then
		if props[Core.Children] ~= nil then
			warn("props[Children] was defined but was overridden by third parameter to createElement!")
		end

		props[Core.Children] = children
	end

	local element = {
		type = Core.Element,
		component = elementType,
		props = props,
	}

	if GlobalConfig.getValue("elementTracing") then
		element.source = ("\n%s\n"):format(debug.traceback())
	end

	return element
end

return createElement