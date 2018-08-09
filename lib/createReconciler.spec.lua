return function()
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local createElement = require(script.Parent.createElement)
	local createSpy = require(script.Parent.createSpy)
	local Type = require(script.Parent.Type)

	local createReconciler = require(script.Parent.createReconciler)

	local noopReconciler = createReconciler(NoopRenderer)

	describe("tree operations", function()
		it("should mount and unmount", function()
			local tree = noopReconciler.mountTree(createElement("StringValue"))

			expect(tree).to.be.ok()

			noopReconciler.unmountTree(tree)
		end)

		it("should mount, reconcile, and unmount", function()
			local tree = noopReconciler.mountTree(createElement("StringValue"))

			expect(tree).to.be.ok()
			expect(tree.rootNode).to.be.ok()

			noopReconciler.reconcileTree(tree, createElement("StringValue"))

			expect(tree.rootNode).to.be.ok()

			noopReconciler.unmountTree(tree)
		end)
	end)

	describe("calling the renderer", function()
		it("should invoke the renderer to mount host nodes", function()
			local mountHostNode = createSpy(NoopRenderer.mountHostNode)

			local renderer = {
				mountHostNode = mountHostNode.value,
			}

			local reconciler = createReconciler(renderer)

			local element = createElement("StringValue")
			local hostParent = Instance.new("IntValue")
			local key = "Some Key"
			local node = reconciler.mountNode(element, hostParent, key)

			expect(Type.of(node)).to.equal(Type.Node)

			expect(mountHostNode.callCount).to.equal(1)

			local values = mountHostNode:captureValues("reconciler", "node")

			expect(values.reconciler).to.equal(reconciler)
			expect(values.node).to.equal(node)
		end)

		it("should invoke the renderer to reconcile host nodes", function()
			local reconcileHostNode = createSpy(NoopRenderer.reconcileHostNode)

			local renderer = {
				mountHostNode = NoopRenderer.mountHostNode,
				reconcileHostNode = reconcileHostNode.value,
			}

			local reconciler = createReconciler(renderer)

			local element = createElement("StringValue")
			local hostParent = Instance.new("IntValue")
			local key = "Key"
			local node = reconciler.mountNode(element, hostParent, key)

			expect(Type.of(node)).to.equal(Type.Node)

			local newElement = createElement("StringValue")
			local newNode = reconciler.reconcileNode(node, newElement)

			expect(newNode).to.equal(node)

			expect(reconcileHostNode.callCount).to.equal(1)

			local values = reconcileHostNode:captureValues("reconciler", "node", "newElement")

			expect(values.reconciler).to.equal(reconciler)
			expect(values.node).to.equal(node)
			expect(values.newElement).to.equal(newElement)
		end)

		it("should invoke the renderer to unmount host nodes", function()
			local unmountHostNode = createSpy(NoopRenderer.unmountHostNode)

			local renderer = {
				mountHostNode = NoopRenderer.mountHostNode,
				unmountHostNode = unmountHostNode.value,
			}

			local reconciler = createReconciler(renderer)

			local element = createElement("StringValue")
			local hostParent = Instance.new("IntValue")
			local key = "Key"
			local node = reconciler.mountNode(element, hostParent, key)

			expect(Type.of(node)).to.equal(Type.Node)

			reconciler.unmountNode(node)

			expect(unmountHostNode.callCount).to.equal(1)

			local values = unmountHostNode:captureValues("reconciler", "node")

			expect(values.reconciler).to.equal(reconciler)
			expect(values.node).to.equal(node)
		end)
	end)
end