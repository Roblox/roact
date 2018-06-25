--[[
	Provides a set of markers used for annotating data in Roact.
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

-- Marker used to specify that the table it is present within is a component.
Core.Element = Symbol.named("Element")

-- The default "stack traceback" if element tracing is not enabled.
-- luacheck: ignore 6
Core._defaultElementTracebackMessage = "\n\t<Use Roact.setGlobalConfig with the 'elementTracing' key to enable detailed tracebacks>\n"

return Core