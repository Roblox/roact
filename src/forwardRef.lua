local createRef = require(script.Parent.createRef)
local Component = require(script.Parent.Component)
local Ref = require(script.Parent.PropMarkers.Ref)

--[[
	Passed a provided ref to given render callback. Can be used to treat class
	components as host components and assign the passed-in ref to the underlying
	host component
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