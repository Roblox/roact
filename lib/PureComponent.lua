--[[
	A version of Component with a `shouldUpdate` method that forces the
	resulting component to be pure.

	Exposed as Roact.PureComponent
]]

local Component = require(script.Parent.Component)

local PureComponent = Component:extend("PureComponent")

-- When extend()ing a component, you don't get an extend method.
-- This is to promote composition over inheritance.
PureComponent.extend = Component.extend

function PureComponent:shouldUpdate(newProps, newState)
	if newState ~= self.state then
		return true
	end

	if newProps == self.props then
		return false
	end

	for key, value in pairs(newProps) do
		if self.props[key] ~= value then
			return true
		end
	end

	for key, value in pairs(self.props) do
		if newProps[key] ~= value then
			return true
		end
	end

	return false
end

return PureComponent