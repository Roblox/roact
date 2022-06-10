return function()
	local assign = require(script.Parent.assign)
	local createElement = require(script.Parent.createElement)
	local createFragment = require(script.Parent.createFragment)
	local createSpy = require(script.Parent.createSpy)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local Type = require(script.Parent.Type)
	local ElementKind = require(script.Parent.ElementKind)

	local createReconciler = require(script.Parent.createReconciler)

	local noopReconciler = createReconciler(NoopRenderer)

	describe("tree operations", function()
		it("should mount and unmount", function()
			local tree = noopReconciler.mountVirtualTree(createElement("StringValue"))

			expect(tree).to.be.ok()

			noopReconciler.unmountVirtualTree(tree)
		end)

		it("should mount, update, and unmount", function()
			local tree = noopReconciler.mountVirtualTree(createElement("StringValue"))

			expect(tree).to.be.ok()

			noopReconciler.updateVirtualTree(tree, createElement("StringValue"))

			noopReconciler.unmountVirtualTree(tree)
		end)
	end)

	describe("booleans", function()
		it("should mount booleans as nil", function()
			local node = noopReconciler.mountVirtualNode(false, nil, "test")
			expect(node).to.equal(nil)
		end)

		it("should unmount nodes if they are updated to a boolean value", function()
			local node = noopReconciler.mountVirtualNode(createElement("StringValue"), nil, "test")

			expect(node).to.be.ok()

			node = noopReconciler.updateVirtualNode(node, true)

			expect(node).to.equal(nil)
		end)
	end)

	describe("invalid elements", function()
		it("should throw errors when attempting to mount invalid elements", function()
			-- These function components return values with incorrect types
			local returnsString = function()
				return "Hello"
			end
			local returnsNumber = function()
				return 1
			end
			local returnsFunction = function()
				return function() end
			end
			local returnsTable = function()
				return {}
			end

			local hostParent = nil
			local key = "Some Key"

			expect(function()
				noopReconciler.mountVirtualNode(createElement(returnsString), hostParent, key)
			end).to.throw()

			expect(function()
				noopReconciler.mountVirtualNode(createElement(returnsNumber), hostParent, key)
			end).to.throw()

			expect(function()
				noopReconciler.mountVirtualNode(createElement(returnsFunction), hostParent, key)
			end).to.throw()

			expect(function()
				noopReconciler.mountVirtualNode(createElement(returnsTable), hostParent, key)
			end).to.throw()
		end)
	end)

	describe("Host components", function()
		it("should invoke the renderer to mount host nodes", function()
			local mountHostNode = createSpy(NoopRenderer.mountHostNode)

			local renderer = assign({}, NoopRenderer, {
				mountHostNode = mountHostNode.value,
			})

			local reconciler = createReconciler(renderer)

			local element = createElement("StringValue")
			local hostParent = nil
			local key = "Some Key"
			local node = reconciler.mountVirtualNode(element, hostParent, key)

			expect(Type.of(node)).to.equal(Type.VirtualNode)

			expect(mountHostNode.callCount).to.equal(1)

			local values = mountHostNode:captureValues("reconciler", "node")

			expect(values.reconciler).to.equal(reconciler)
			expect(values.node).to.equal(node)
		end)

		it("should invoke the renderer to update host nodes", function()
			local updateHostNode = createSpy(NoopRenderer.updateHostNode)

			local renderer = assign({}, NoopRenderer, {
				mountHostNode = NoopRenderer.mountHostNode,
				updateHostNode = updateHostNode.value,
			})

			local reconciler = createReconciler(renderer)

			local element = createElement("StringValue")
			local hostParent = nil
			local key = "Key"
			local node = reconciler.mountVirtualNode(element, hostParent, key)

			expect(Type.of(node)).to.equal(Type.VirtualNode)

			local newElement = createElement("StringValue")
			local newNode = reconciler.updateVirtualNode(node, newElement)

			expect(newNode).to.equal(node)

			expect(updateHostNode.callCount).to.equal(1)

			local values = updateHostNode:captureValues("reconciler", "node", "newElement")

			expect(values.reconciler).to.equal(reconciler)
			expect(values.node).to.equal(node)
			expect(values.newElement).to.equal(newElement)
		end)

		it("should invoke the renderer to unmount host nodes", function()
			local unmountHostNode = createSpy(NoopRenderer.unmountHostNode)

			local renderer = assign({}, NoopRenderer, {
				mountHostNode = NoopRenderer.mountHostNode,
				unmountHostNode = unmountHostNode.value,
			})

			local reconciler = createReconciler(renderer)

			local element = createElement("StringValue")
			local hostParent = nil
			local key = "Key"
			local node = reconciler.mountVirtualNode(element, hostParent, key)

			expect(Type.of(node)).to.equal(Type.VirtualNode)

			reconciler.unmountVirtualNode(node)

			expect(unmountHostNode.callCount).to.equal(1)

			local values = unmountHostNode:captureValues("reconciler", "node")

			expect(values.reconciler).to.equal(reconciler)
			expect(values.node).to.equal(node)
		end)
	end)

	describe("Function components", function()
		it("should mount and unmount function components", function()
			local componentSpy = createSpy(function(_props)
				return nil
			end)

			local element = createElement(componentSpy.value, {
				someValue = 5,
			})
			local hostParent = nil
			local key = "A Key"
			local node = noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(Type.of(node)).to.equal(Type.VirtualNode)

			expect(componentSpy.callCount).to.equal(1)

			local calledWith = componentSpy:captureValues("props")

			expect(calledWith.props).to.be.a("table")
			expect(calledWith.props.someValue).to.equal(5)

			noopReconciler.unmountVirtualNode(node)

			expect(componentSpy.callCount).to.equal(1)
		end)

		it("should mount single children of function components", function()
			local childComponentSpy = createSpy(function(_props)
				return nil
			end)

			local parentComponentSpy = createSpy(function(props)
				return createElement(childComponentSpy.value, {
					value = props.value + 1,
				})
			end)

			local element = createElement(parentComponentSpy.value, {
				value = 13,
			})
			local hostParent = nil
			local key = "A Key"
			local node = noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(Type.of(node)).to.equal(Type.VirtualNode)

			expect(parentComponentSpy.callCount).to.equal(1)
			expect(childComponentSpy.callCount).to.equal(1)

			local parentCalledWith = parentComponentSpy:captureValues("props")
			local childCalledWith = childComponentSpy:captureValues("props")

			expect(parentCalledWith.props).to.be.a("table")
			expect(parentCalledWith.props.value).to.equal(13)

			expect(childCalledWith.props).to.be.a("table")
			expect(childCalledWith.props.value).to.equal(14)

			noopReconciler.unmountVirtualNode(node)

			expect(parentComponentSpy.callCount).to.equal(1)
			expect(childComponentSpy.callCount).to.equal(1)
		end)

		it("should mount fragments returned by function components", function()
			local childAComponentSpy = createSpy(function(_props)
				return nil
			end)

			local childBComponentSpy = createSpy(function(_props)
				return nil
			end)

			local parentComponentSpy = createSpy(function(props)
				return createFragment({
					A = createElement(childAComponentSpy.value, {
						value = props.value + 1,
					}),
					B = createElement(childBComponentSpy.value, {
						value = props.value + 5,
					}),
				})
			end)

			local element = createElement(parentComponentSpy.value, {
				value = 17,
			})
			local hostParent = nil
			local key = "A Key"
			local node = noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(Type.of(node)).to.equal(Type.VirtualNode)

			expect(parentComponentSpy.callCount).to.equal(1)
			expect(childAComponentSpy.callCount).to.equal(1)
			expect(childBComponentSpy.callCount).to.equal(1)

			local parentCalledWith = parentComponentSpy:captureValues("props")
			local childACalledWith = childAComponentSpy:captureValues("props")
			local childBCalledWith = childBComponentSpy:captureValues("props")

			expect(parentCalledWith.props).to.be.a("table")
			expect(parentCalledWith.props.value).to.equal(17)

			expect(childACalledWith.props).to.be.a("table")
			expect(childACalledWith.props.value).to.equal(18)

			expect(childBCalledWith.props).to.be.a("table")
			expect(childBCalledWith.props.value).to.equal(22)

			noopReconciler.unmountVirtualNode(node)

			expect(parentComponentSpy.callCount).to.equal(1)
			expect(childAComponentSpy.callCount).to.equal(1)
			expect(childBComponentSpy.callCount).to.equal(1)
		end)
	end)

	describe("Fragments", function()
		it("should mount fragments", function()
			local fragment = createFragment({})
			local node = noopReconciler.mountVirtualNode(fragment, nil, "test")

			expect(node).to.be.ok()
			expect(ElementKind.of(node.currentElement)).to.equal(ElementKind.Fragment)
		end)

		it("should mount an empty fragment", function()
			local emptyFragment = createFragment({})
			local node = noopReconciler.mountVirtualNode(emptyFragment, nil, "test")

			expect(node).to.be.ok()

			local nextNode = next(node.children)
			expect(nextNode).to.never.be.ok()
		end)

		it("should mount all fragment's children", function()
			local childComponentSpy = createSpy(function(_props)
				return nil
			end)
			local elements = {}
			local totalElements = 5

			for i = 1, totalElements do
				elements["key" .. tostring(i)] = createElement(childComponentSpy.value, {})
			end

			local fragments = createFragment(elements)
			local node = noopReconciler.mountVirtualNode(fragments, nil, "test")

			expect(node).to.be.ok()
			expect(childComponentSpy.callCount).to.equal(totalElements)
		end)
	end)
end
