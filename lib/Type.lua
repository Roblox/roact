--[[
	Contains markers for annotating objects with types.

	To set the type of an object, use `Type` as a key and the actual marker as
	the value:

		local foo = {
			[Type] = Type.Foo,
		}
]]

local Symbol = require(script.Parent.Symbol)

local Type = newproxy(true)

local TypeInternal = {
	Tree = Symbol.named("RoactTree"),
	Node = Symbol.named("RoactNode"),
	Element = Symbol.named("RoactElement"),
}

function TypeInternal.of(value)
	if typeof(value) ~= "table" then
		return nil
	end

	return value[Type]
end

function TypeInternal.is(value, typeMarker)
	assert(typeof(typeMarker) == "userdata")

	return typeof(value) == "table" and value[Type] == typeMarker
end

getmetatable(Type).__index = TypeInternal

return Type