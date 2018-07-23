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

	-- Too verbose?
	StatefulComponentClass = Symbol.named("StatefulComponentClass"),
	StatefulComponentInstance = Symbol.named("StatefulComponentInstance"),
}

function TypeInternal.of(value)
	if typeof(value) ~= "table" then
		return nil
	end

	return value[Type]
end

getmetatable(Type).__index = TypeInternal

setmetatable(TypeInternal, {
	__index = function(self, key)
		error(("Invalid Type key %q"):format(tostring(key)))
	end,
})

return Type