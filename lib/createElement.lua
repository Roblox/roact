local Core = require(script.Parent.Core)
local GlobalConfig = require(script.Parent.GlobalConfig)

local function merge(...) -- DRY, more like Do rWhatever, YOLO
	local result = {}

	for i = 1, select("#", ...) do
		local entry = select(i, ...)

		for key, value in pairs(entry) do
			if value == Core.None then
				result[key] = nil
			else
				result[key] = value
			end
		end
	end

	return result
end

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

	if elementType.defaultProps then -- I have no idea what I'm doing
		-- We only allocate another prop table if there are props that are
		-- falling back to their default.
		for key in pairs(elementType.defaultProps) do
			if props[key] == nil then
				props = merge(elementType.defaultProps, props)
				break
			end
		end
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