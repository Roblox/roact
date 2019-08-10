local Component = require(script.Parent.Component)
local Portal = require(script.Parent.Portal)
local createElement = require(script.Parent.createElement)
local isValidElementType = require(script.Parent.isValidElementType)

return function()
	it("should return true for a stateful component class", function()
		local MyStatefulComponent = Component:extend("MyStatefulComponent")
		expect(isValidElementType(MyStatefulComponent)).to.equal(true)
	end)

	it("should return true for a function component", function()
		local MyFunctionComponent = function(props)
			return createElement("Frame", {})
		end
		expect(isValidElementType(MyFunctionComponent)).to.equal(true)
	end)

	-- There's no way to guarantee the return type for a function in Lua at the moment
	itSKIP("should not return true for a function that returns an invalid type", function() end)

	it("should return true for a string representing a host instance type", function()
		local host = "Frame"
		expect(isValidElementType(host)).to.equal(true)
	end)

	-- In the future, an exhaustive enum of all possible host instance types could enable this check
	itSKIP("should not return true for a function that returns an invalid type", function() end)

	it("should return true for a portal", function()
		expect(isValidElementType(Portal)).to.equal(true)
	end)
end