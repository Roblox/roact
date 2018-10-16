--[[
	Contains markers for annotating objects with types.

	To set the type of an object, use `Type` as a key and the actual marker as
	the value:

		local foo = {
			[Type] = Type.Foo,
		}
]]

local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)

local Type = newproxy(true)

local TypeInternal = {
	Element = Symbol.named("RoactElement"),
	Node = Symbol.named("RoactNode"),
	Ref = Symbol.named("RoactRef"),
	StatefulComponentClass = Symbol.named("StatefulComponentClass"),
	StatefulComponentInstance = Symbol.named("StatefulComponentInstance"),
	Tree = Symbol.named("RoactTree"),
}

function TypeInternal.of(value)
	if typeof(value) ~= "table" then
		return nil
	end

	return value[Type]
end

getmetatable(Type).__index = TypeInternal

strict(TypeInternal, "Type")

return Type