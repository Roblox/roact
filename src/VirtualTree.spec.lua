return function()
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local RobloxRenderer = require(script.Parent.RobloxRenderer)

	local robloxReconciler = createReconciler(RobloxRenderer)

	describe("getTestRenderOutput", function()
		it("should return a ShallowWrapper with the given depth", function()
			local function Component()
				return createElement("Frame")
			end
			local element = createElement(Component)

			local tree = robloxReconciler.mountVirtualTree(element)

			local wrapper = tree:getTestRenderOutput({
				depth = 0,
			})

			expect(wrapper.type.functionComponent).to.equal(Component)
		end)
	end)
end