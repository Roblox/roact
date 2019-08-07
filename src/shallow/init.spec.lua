return function()
	local createElement = require(script.Parent.Parent.createElement)
	local shallow = require(script.Parent)

	it("should return a shallow wrapper with depth = 1 by default", function()
		local element = createElement("Frame", {}, {
			Child = createElement("Frame", {}, {
				SubChild = createElement("Frame"),
			}),
		})

		local wrapper = shallow(element)
		local childWrapper = wrapper:findUnique()

		expect(childWrapper:childrenCount()).to.equal(0)
	end)
end