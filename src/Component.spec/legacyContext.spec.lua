return function()
	local assertDeepEqual = require(script.Parent.Parent.assertDeepEqual)
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be provided as a mutable self._context in Component:init", function()
		local Provider = Component:extend("Provider")

		function Provider:init()
			self._context.foo = "bar"
		end

		function Provider:render() end

		local element = createElement(Provider)
		local hostParent = nil
		local hostKey = "Provider"
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey)

		local expectedContext = {
			foo = "bar",
		}

		assertDeepEqual(node.legacyContext, expectedContext)
	end)

	it("should be inherited from parent stateful nodes", function()
		local Consumer = Component:extend("Consumer")

		local capturedContext
		function Consumer:init()
			capturedContext = self._context
		end

		function Consumer:render() end

		local Parent = Component:extend("Parent")

		function Parent:render()
			return createElement(Consumer)
		end

		local element = createElement(Parent)
		local hostParent = nil
		local hostKey = "Parent"
		local context = {
			hello = "world",
			value = 6,
		}
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey, nil, context)

		expect(capturedContext).never.to.equal(context)
		expect(capturedContext).never.to.equal(node.legacyContext)
		assertDeepEqual(node.legacyContext, context)
		assertDeepEqual(capturedContext, context)
	end)

	it("should be inherited from parent function nodes", function()
		local Consumer = Component:extend("Consumer")

		local capturedContext
		function Consumer:init()
			capturedContext = self._context
		end

		function Consumer:render() end

		local function Parent()
			return createElement(Consumer)
		end

		local element = createElement(Parent)
		local hostParent = nil
		local hostKey = "Parent"
		local context = {
			hello = "world",
			value = 6,
		}
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey, nil, context)

		expect(capturedContext).never.to.equal(context)
		expect(capturedContext).never.to.equal(node.legacyContext)
		assertDeepEqual(node.legacyContext, context)
		assertDeepEqual(capturedContext, context)
	end)

	it("should contain values put into the tree by parent nodes", function()
		local Consumer = Component:extend("Consumer")

		local capturedContext
		function Consumer:init()
			capturedContext = self._context
		end

		function Consumer:render() end

		local Provider = Component:extend("Provider")

		function Provider:init()
			self._context.frob = "ulator"
		end

		function Provider:render()
			return createElement(Consumer)
		end

		local element = createElement(Provider)
		local hostParent = nil
		local hostKey = "Consumer"
		local context = {
			dont = "try it",
		}
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey, nil, context)

		local initialContext = {
			dont = "try it",
		}

		local expectedContext = {
			dont = "try it",
			frob = "ulator",
		}

		-- Because components mutate context, we're careful with equality
		expect(node.legacyContext).never.to.equal(context)
		expect(capturedContext).never.to.equal(context)
		expect(capturedContext).never.to.equal(node.legacyContext)

		assertDeepEqual(context, initialContext)
		assertDeepEqual(node.legacyContext, expectedContext)
		assertDeepEqual(capturedContext, expectedContext)
	end)

	it("should transfer context to children that are replaced", function()
		local ConsumerA = Component:extend("ConsumerA")

		local capturedContextA
		function ConsumerA:init()
			self._context.A = "hello"

			capturedContextA = self._context
		end

		function ConsumerA:render() end

		local ConsumerB = Component:extend("ConsumerB")

		local capturedContextB
		function ConsumerB:init()
			self._context.B = "hello"

			capturedContextB = self._context
		end

		function ConsumerB:render() end

		local Provider = Component:extend("Provider")

		function Provider:init()
			self._context.frob = "ulator"
		end

		function Provider:render()
			local useConsumerB = self.props.useConsumerB

			if useConsumerB then
				return createElement(ConsumerB)
			else
				return createElement(ConsumerA)
			end
		end

		local hostParent = nil
		local hostKey = "Consumer"

		local element = createElement(Provider)
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey)

		local expectedContextA = {
			frob = "ulator",
			A = "hello",
		}

		assertDeepEqual(capturedContextA, expectedContextA)

		local expectedContextB = {
			frob = "ulator",
			B = "hello",
		}

		local replacedElement = createElement(Provider, {
			useConsumerB = true,
		})
		noopReconciler.updateVirtualNode(node, replacedElement)

		assertDeepEqual(capturedContextB, expectedContextB)
	end)
end
