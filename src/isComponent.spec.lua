local Component = require(script.Parent.Component)
local Portal = require(script.Parent.Portal)
local createElement = require(script.Parent.createElement)
local isComponent = require(script.Parent.isComponent)

return function()
	it("should return true for a stateful component class", function()
		local MyStatefulComponent = Component:extend("MyStatefulComponent")
		expect(isComponent(MyStatefulComponent)).to.equal(true)
	end)

	it("should return true for a function component", function()
		local MyFunctionComponent = function(props)
			return createElement("Frame", {})
		end
		expect(isComponent(MyFunctionComponent)).to.equal(true)
	end)

	-- There's no way to guarantee the return type for a function in Lua at the moment
	itSKIP("should not return true for a function that returns an invalid type", function() end)

	it("should return true for a string representing a host instance type", function()
		local host = "Frame"
		expect(isComponent(host)).to.equal(true)
	end)

	-- In the future, an exhaustive enum of all possible host instance types could enable this check
	itSKIP("should not return true for a function that returns an invalid type", function() end)

	it("should return true for a portal", function()
		expect(isComponent(Portal)).to.equal(true)
	end)
end