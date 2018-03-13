--[[
	Provides methods and data core to the implementation of the Roact
	Virtual DOM.

	This module doesn't interact with the Roblox hierarchy and should have no
	dependencies on other Roact modules.
]]

local Symbol = require(script.Parent.Symbol)

local Core = {}

-- Marker used to specify children of a node.
Core.Children = Symbol.named("Children")

-- Marker used to specify a callback to receive the underlying Roblox object.
Core.Ref = Symbol.named("Ref")

-- Marker used to specify that a component is a Roact Portal.
Core.Portal = Symbol.named("Portal")

-- Marker used to specify that the value is nothing, because nil cannot be stored in tables.
Core.None = Symbol.named("None")

Core._DEBUG_ENABLED = false

function Core.DEBUG_ENABLE()
	if Core._DEBUG_ENABLED then
		error("Can only call Roact.DEBUG_ENABLE once!", 2)
	end

	Core._DEBUG_ENABLED = true
end

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
	Is this element backed by a Roblox instance directly?
]]
function Core.isPrimitiveElement(element)
	if type(element) ~= "table" then
		return false
	end

	return type(element.type) == "string"
end

--[[
	Is this element defined by a pure function?
]]
function Core.isFunctionalElement(element)
	if type(element) ~= "table" then
		return false
	end

	return type(element.type) == "function"
end

--[[
	Is this element defined by a component class?
]]
function Core.isStatefulElement(element)
	if type(element) ~= "table" then
		return false
	end

	return type(element.type) == "table"
end

--[[
	Is this element a Portal?
]]
function Core.isPortal(element)
	if type(element) ~= "table" then
		return false
	end

	return element.type == Core.Portal
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
		isElement = true,
		type = elementType,
		props = props,
	}

	if Core._DEBUG_ENABLED then
		element.source = ("\n%s\n"):format(debug.traceback())
	end

	return element
end

return Core