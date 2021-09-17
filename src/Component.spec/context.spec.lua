return function()
	local assertDeepEqual = require(script.Parent.Parent.assertDeepEqual)
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local oneChild = require(script.Parent.Parent.oneChild)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be provided as an internal api on Component", function()
		local Provider = Component:extend("Provider")

		function Provider:init()
			self:__addContext("foo", "bar")
		end

		function Provider:render() end

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
			capturedContext = {
				hello = self:__getContext("hello"),
				value = self:__getContext("value"),
			}
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
			capturedContext = {
				hello = self:__getContext("hello"),
				value = self:__getContext("value"),
			}
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
		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey, context)

		expect(capturedContext).never.to.equal(context)
		expect(capturedContext).never.to.equal(node.context)
		assertDeepEqual(node.context, context)
		assertDeepEqual(capturedContext, context)
	end)

	it("should not copy the context table if it doesn't need to", function()
		local Parent = Component:extend("Parent")

		function Parent:init()
			self:__addContext("parent", "I'm here!")
		end

		function Parent:render()
			-- Create some child element
			return createElement(function() end)
		end

		local element = createElement(Parent)
		local hostParent = nil
		local hostKey = "Parent"
		local parentNode = noopReconciler.mountVirtualNode(element, hostParent, hostKey)

		local expectedContext = {
			parent = "I'm here!",
		}

		assertDeepEqual(parentNode.context, expectedContext)

		local childNode = oneChild(parentNode.children)

		-- Parent and child should have the same context table
		expect(parentNode.context).to.equal(childNode.context)
	end)

	it("should not allow context to move up the tree", function()
		local ChildProvider = Component:extend("ChildProvider")

		function ChildProvider:init()
			self:__addContext("child", "I'm here too!")
		end

		function ChildProvider:render() end

		local ParentProvider = Component:extend("ParentProvider")

		function ParentProvider:init()
			self:__addContext("parent", "I'm here!")
		end

		function ParentProvider:render()
			return createElement(ChildProvider)
		end

		local element = createElement(ParentProvider)
		local hostParent = nil
		local hostKey = "Parent"

		local parentNode = noopReconciler.mountVirtualNode(element, hostParent, hostKey)
		local childNode = oneChild(parentNode.children)

		local expectedParentContext = {
			parent = "I'm here!",
			-- Context does not travel back up
		}

		local expectedChildContext = {
			parent = "I'm here!",
			child = "I'm here too!",
		}

		assertDeepEqual(parentNode.context, expectedParentContext)
		assertDeepEqual(childNode.context, expectedChildContext)
	end)

	it("should contain values put into the tree by parent nodes", function()
		local Consumer = Component:extend("Consumer")

		local capturedContext
		function Consumer:init()
			capturedContext = {
				dont = self:__getContext("dont"),
				frob = self:__getContext("frob"),
			}
		end

		function Consumer:render() end

		local Provider = Component:extend("Provider")

		function Provider:init()
			self:__addContext("frob", "ulator")
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

	it("should transfer context to children that are replaced", function()
		local ConsumerA = Component:extend("ConsumerA")

		local function captureAllContext(component)
			return {
				A = component:__getContext("A"),
				B = component:__getContext("B"),
				frob = component:__getContext("frob"),
			}
		end

		local capturedContextA
		function ConsumerA:init()
			self:__addContext("A", "hello")

			capturedContextA = captureAllContext(self)
		end

		function ConsumerA:render() end

		local ConsumerB = Component:extend("ConsumerB")

		local capturedContextB
		function ConsumerB:init()
			self:__addContext("B", "hello")

			capturedContextB = captureAllContext(self)
		end

		function ConsumerB:render() end

		local Provider = Component:extend("Provider")

		function Provider:init()
			self:__addContext("frob", "ulator")
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
