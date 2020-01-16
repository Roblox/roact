--[[
	Mirrors a subset of values from Type.lua for external use, allowing
	type checking on Roact objects without exposing internal Type symbols

	TypeMirror: {
		Type: Roact.Type,
		typeOf: function(value: table) -> Roact.Type | nil
	}
]]

local Type = require(script.Parent.Type)
local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)

local ALLOWED_TYPES = {
	Type.Binding,
	Type.Element,
	Type.HostChangeEvent,
	Type.HostEvent,
	Type.StatefulComponentClass,
	Type.StatefulComponentInstance,
	Type.VirtualTree
}

local MirroredType = {}
for _, type in ipairs(ALLOWED_TYPES) do
	local name = Type.nameOf(type)
	MirroredType[name] = Symbol.named("Roact" .. name)
end

setmetatable(MirroredType, {
	__tostring = function()
		return "RoactType"
	end
})

strict(MirroredType, "Type")

local Mirror = {
	typeList = ALLOWED_TYPES,
	Type = MirroredType,
	typeOf = function(value)
		local name = Type.nameOf(Type.of(value))
		if not name then
			return nil
		end
		return MirroredType[name]
	end,
}

strict(Mirror, "TypeMirror")

return Mirror