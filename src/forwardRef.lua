local createRef = require(script.Parent.createRef)
local Component = require(script.Parent.Component)
local Ref = require(script.Parent.PropMarkers.Ref)

--[[
	
]]
local function forwardRef(render)
	local ForwardRefComponent = Component:extend("ForwardRefContainer")

	function ForwardRefComponent:init()
		self.defaultRef = createRef()
	end

	function ForwardRefComponent:render()
		return render(self.props, self.props[Ref] or self.defaultRef)
	end

	return ForwardRefComponent
end

return forwardRef