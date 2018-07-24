local Type = require(script.Parent.Type)

local Component = {}
Component[Type] = Type.StatefulComponentClass
Component.__index = Component

function Component:extend(name)
	assert(typeof(name) == "string")

	local class = {}
	class[Type] = Type.StatefulComponentInstance
	class.__index = class

	for key, value in pairs(Component) do
		if key ~= "extend" then
			class[key] = value
		end
	end

	return class
end

function Component:__new(props)
	assert(typeof(props) == "table")

	local internal = {
	}

	local instance = {
		__internal = internal,
	}

	setmetatable(instance, self)

	return instance
end

function Component:render()
	error("overwrite render please")
end

return Component