--[[
	Contains markers for annotating the type of an element.

	Use `ElementKind` as a key, and values from it as the value.

		local element = {
			[ElementKind] = ElementKind.Host,
		}
]]

local Symbol = require(script.Parent.Symbol)
local Core = require(script.Parent.Core)
local strict = require(script.Parent.strict)

local ElementKind = newproxy(true)

local ElementKindInternal = {
	Portal = Symbol.named("Portal"),
	Host = Symbol.named("Host"),
	Function = Symbol.named("Function"),
	Stateful = Symbol.named("Stateful"),
}

function ElementKindInternal.of(value)
	if typeof(value) ~= "table" then
		return nil
	end

	return value[ElementKind]
end

local componentTypesToKinds = {
	["string"] = ElementKindInternal.Host,
	["function"] = ElementKindInternal.Function,
	["table"] = ElementKindInternal.Stateful,
}

function ElementKindInternal.fromComponent(component)
	if component == Core.Portal then
		return ElementKind.Portal
	else
		return componentTypesToKinds[typeof(component)]
	end
end

getmetatable(ElementKind).__index = ElementKindInternal

strict(ElementKindInternal, "ElementKind")

return ElementKind