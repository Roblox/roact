return function()
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local VirtualTree = require(script.Parent.VirtualTree)

	local noopReconciler = createReconciler(NoopRenderer)

	describe("tree operations", function()
		it("should mount and unmount", function()
			local tree = VirtualTree.mountWithOptions(createElement("StringValue"), {
				reconciler = noopReconciler,
			})

			expect(tree).to.be.ok()

			VirtualTree.unmount(tree)
		end)

		it("should mount, update, and unmount", function()
			local tree = VirtualTree.mountWithOptions(createElement("StringValue"), {
				reconciler = noopReconciler,
			})

			expect(tree).to.be.ok()

			VirtualTree.update(tree, createElement("StringValue"))

			VirtualTree.unmount(tree)
		end)
	end)

	describe("getShallowWrapper", function()
		it("should return a shallow wrapper", function()
			local tree = VirtualTree.mountWithOptions(createElement("StringValue"), {
				reconciler = noopReconciler,
			})

			expect(tree).to.be.ok()

			local wrapper = tree:getShallowWrapper()

			expect(wrapper).to.be.ok()
			expect(wrapper.component).to.equal("StringValue")
		end)
	end)
end