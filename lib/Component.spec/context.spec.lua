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

		function Provider:render()
		end

		local element = createElement(Provider)
		local hostParent = nil
		local hostKey = "Provider"
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey)

		local expectedContext = {
			foo = "bar",
		}

		assertDeepEqual(node.context, expectedContext)
	end)

	it("should be inherited from parent stateful nodes", function()
		local Consumer = Component:extend("Consumer")

		local capturedContext
		function Consumer:init()
			capturedContext = self._context
		end

		function Consumer:render()
		end

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
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey, context)

		expect(capturedContext).never.to.equal(context)
		expect(capturedContext).never.to.equal(node.context)
		assertDeepEqual(node.context, context)
		assertDeepEqual(capturedContext, context)
	end)

	it("should be inherited from parent function nodes", function()
		local Consumer = Component:extend("Consumer")

		local capturedContext
		function Consumer:init()
			capturedContext = self._context
		end

		function Consumer:render()
		end

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
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey, context)

		expect(capturedContext).never.to.equal(context)
		expect(capturedContext).never.to.equal(node.context)
		assertDeepEqual(node.context, context)
		assertDeepEqual(capturedContext, context)
	end)

	it("should contain values put into the tree by parent nodes", function()
		local Consumer = Component:extend("Consumer")

		local capturedContext
		function Consumer:init()
			capturedContext = self._context
		end

		function Consumer:render()
		end

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
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey, context)

		local initialContext = {
			dont = "try it",
		}

		local expectedContext = {
			dont = "try it",
			frob = "ulator",
		}

		-- Because components mutate context, we're careful with equality
		expect(node.context).never.to.equal(context)
		expect(capturedContext).never.to.equal(context)
		expect(capturedContext).never.to.equal(node.context)

		assertDeepEqual(context, initialContext)
		assertDeepEqual(node.context, expectedContext)
		assertDeepEqual(capturedContext, expectedContext)
	end)

	itSKIP("should transfer context to children that are replaced", function()
		-- TODO: Write a test that
		-- 1. Renders a component tree with a context consumer component
		-- 2. Updates that tree with a different consumer component at the same key
		-- 3. Confirm that context captured from initial consumer deep-equals context captured from new consumer
	end)
end