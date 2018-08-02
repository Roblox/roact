return function()
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local createElement = require(script.Parent.createElement)

	local createReconciler = require(script.Parent.createReconciler)

	local noopReconciler = createReconciler(NoopRenderer)

	describe("tree operations", function()
		it("should mount and unmount given an element", function()
			local tree = noopReconciler.mountTree(createElement("StringValue"))

			expect(tree).to.be.ok()

			noopReconciler.unmountTree(tree)
		end)
	end)
end