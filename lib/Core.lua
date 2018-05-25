--[[
	Provides methods and data core to the implementation of the Roact
	Virtual DOM.

	This module doesn't interact with the Roblox hierarchy.
]]

local Symbol = require(script.Parent.Symbol)
local GlobalConfig = require(script.Parent.GlobalConfig)

local Core = {}

-- Marker used to specify children of a node.
Core.Children = Symbol.named("Children")

-- Marker used to specify a callback to receive the underlying Roblox object.
Core.Ref = Symbol.named("Ref")

-- Marker used to specify that a component is a Roact Portal.
Core.Portal = Symbol.named("Portal")

-- Marker used to specify that the value is nothing, because nil cannot be stored in tables.
Core.None = Symbol.named("None")

-- Marker used to specify that the table it is present within is a component.
Core.Element = Symbol.named("Element")

-- The default "stack traceback" if element tracing is not enabled.
Core._defaultElementTracebackMessage = "\n\t<Use Roact.setGlobalConfig with the 'elementTracing' key to enable detailed tracebacks>\n"

--[[
	Utility to retrieve one child out the children passed to a component.

	If passed nil or an empty table, will return nil.

	Throws an error if passed more than one child, but can be passed zero.
]]
function Core.oneChild(children)
	if not children then
		return
	end

	local key, child = next(children)

	if not child then
		return
	end

	local after = next(children, key)

	if after then
		error("Expected at most child, had more than one child.", 2)
	end

	return child
end

--[[
	Creates a new Roact element of the given type.

	Does not create any concrete objects.
]]
function Core.createElement(elementType, props, children)
	if elementType == nil then
		error(("Expected elementType as an argument to createElement!"), 2)
	end

	props = props or {}

	if children then
		if props[Core.Children] then
			warn("props[Children] was defined but was overridden by third parameter to createElement!")
		end

		props[Core.Children] = children
	end

	local element = {
		component = elementType,
		type = Core.Element,
		props = props,
	}

	if GlobalConfig.getValue("elementTracing") then
		element.source = ("\n%s\n"):format(debug.traceback())
	end

	return element
end

return Core