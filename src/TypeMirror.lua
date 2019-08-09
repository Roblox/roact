--[[
	Mirrors a subset of values from Type.lua for external use, allowing
	type checking on Roact objects without exposing internal Type symbols

	TypeMirror: {
		Type: Roact.Type,
		typeof: function(value: table) -> Roact.Type | nil
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

local MirroredType = newproxy(true)
local MirroredTypeInternal = {}
for _, type in ipairs(ALLOWED_TYPES) do
	local name = Type.nameOf(type)
	MirroredTypeInternal[name] = Symbol.named("Roact" .. name)
end

getmetatable(MirroredType).__index = MirroredTypeInternal
getmetatable(MirroredType).__tostring = function()
	return "RoactType"
end

strict(MirroredTypeInternal, "Type")

local Mirror = newproxy(true)
local MirrorInternal = {
	Type = MirroredType,
	typeOf = function(value)
		local name = Type.nameOf(Type.of(value))
		if not name then
			return nil
		end
		return MirroredTypeInternal[name]
	end,
}

getmetatable(Mirror).__index = MirrorInternal
getmetatable(Mirror).__tostring = function()
	return "TypeMirror"
end

strict(MirrorInternal, "TypeMirror")

return Mirror