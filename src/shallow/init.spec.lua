return function()
	local RoactRoot = script.Parent.Parent

	local createElement = require(RoactRoot.createElement)
	local createReconciler = require(RoactRoot.createReconciler)
	local RobloxRenderer = require(RoactRoot.RobloxRenderer)
	local shallow = require(script.Parent)

	local robloxReconciler = createReconciler(RobloxRenderer)

	local shallowTreeKey = "RoactTree"

	it("should return a shallow wrapper with depth = 1 by default", function()
		local element = createElement("Frame", {}, {
			Child = createElement("Frame", {}, {
				SubChild = createElement("Frame"),
			}),
		})

		local rootNode = robloxReconciler.mountVirtualNode(element, nil, shallowTreeKey)
		local wrapper = shallow(rootNode)
		local childWrapper = wrapper:findUnique()

		expect(childWrapper:childrenCount()).to.equal(0)
	end)
end