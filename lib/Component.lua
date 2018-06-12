local Component = {}
Component.__index = Component

function Component:extend()
	local class = {}
	class.__index = class

	for key, value in pairs(Component) do
		if key ~= "extend" then
			class[key] = value
		end
	end

	return class
end

function Component:__new(tree)
	local internal = {
		tree = tree,
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

function Component:DEBUG_scheduleRender()
	local internal = self.__internal

	-- TODO: access internal.tree to schedule a render
end

return Component