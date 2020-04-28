local assign = require(script.Parent.assign)
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
		local newProps = assign({}, self.props, {
			[Ref] = self.props[Ref] or self.defaultRef
		})

		return render(newProps)
	end

	return ForwardRefComponent
end

return forwardRef