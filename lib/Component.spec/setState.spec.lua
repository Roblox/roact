return function()
	local createElement = require(script.Parent.Parent.createElement)
	local createFragment = require(script.Parent.Parent.createFragment)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local createSpy = require(script.Parent.Parent.createSpy)
	local None = require(script.Parent.Parent.None)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	describe("setState", function()
		it("should not trigger an extra update when called in init", function()
			local renderCount = 0
			local updateCount = 0
			local capturedState

			local InitComponent = Component:extend("InitComponent")

			function InitComponent:init()
				self:setState({
					a = 1
				})
			end

			function InitComponent:willUpdate()
				updateCount = updateCount + 1
			end

			function InitComponent:render()
				renderCount = renderCount + 1
				capturedState = self.state
				return nil
			end

			local initElement = createElement(InitComponent)

			noopReconciler.mountVirtualTree(initElement)

			expect(renderCount).to.equal(1)
			expect(updateCount).to.equal(0)
			expect(capturedState.a).to.equal(1)
		end)

		it("should throw when called in render", function()
			local RenderComponent = Component:extend("RenderComponent")

			function RenderComponent:render()
				self:setState({
					a = 1
				})
			end

			local renderElement = createElement(RenderComponent)

			expect(function()
				noopReconciler.mountVirtualTree(renderElement)
			end).to.throw()
		end)

		it("should throw when called in shouldUpdate", function()
			local TestComponent = Component:extend("TestComponent")

			function TestComponent:render()
				return nil
			end

			function TestComponent:shouldUpdate()
				self:setState({
					a = 1
				})
			end

			local initialElement = createElement(TestComponent)
			local updatedElement = createElement(TestComponent)

			local tree = noopReconciler.mountVirtualTree(initialElement)

			expect(function()
				noopReconciler.updateVirtualTree(tree, updatedElement)
			end).to.throw()
		end)

		it("should throw when called in willUpdate", function()
			local TestComponent = Component:extend("TestComponent")

			function TestComponent:render()
				return nil
			end

			function TestComponent:willUpdate()
				self:setState({
					a = 1
				})
			end

			local initialElement = createElement(TestComponent)
			local updatedElement = createElement(TestComponent)
			local tree = noopReconciler.mountVirtualTree(initialElement)

			expect(function()
				noopReconciler.updateVirtualTree(tree, updatedElement)
			end).to.throw()
		end)

		it("should throw when called in willUnmount", function()
			local TestComponent = Component:extend("TestComponent")

			function TestComponent:render()
				return nil
			end

			function TestComponent:willUnmount()
				self:setState({
					a = 1
				})
			end

			local element = createElement(TestComponent)
			local tree = noopReconciler.mountVirtualTree(element)

			expect(function()
				noopReconciler.unmountVirtualTree(tree)
			end).to.throw()
		end)

		it("should remove values from state when the value is None", function()
			local TestComponent = Component:extend("TestComponent")
			local setStateCallback, getStateCallback

			function TestComponent:init()
				setStateCallback = function(newState)
					self:setState(newState)
				end

				getStateCallback = function()
					return self.state
				end

				self:setState({
					value = 0
				})
			end

			function TestComponent:render()
				return nil
			end

			local element = createElement(TestComponent)
			local instance = noopReconciler.mountVirtualNode(element, nil, "Test")

			expect(getStateCallback().value).to.equal(0)

			setStateCallback({
				value = None
			})

			expect(getStateCallback().value).to.equal(nil)

			noopReconciler.unmountVirtualNode(instance)
		end)

		it("should invoke functions to compute a partial state", function()
			local TestComponent = Component:extend("TestComponent")
			local setStateCallback, getStateCallback, getPropsCallback

			function TestComponent:init()
				setStateCallback = function(newState)
					self:setState(newState)
				end

				getStateCallback = function()
					return self.state
				end

				getPropsCallback = function()
					return self.props
				end

				self:setState({
					value = 0
				})
			end

			function TestComponent:render()
				return nil
			end

			local element = createElement(TestComponent)
			local instance = noopReconciler.mountVirtualNode(element, nil, "Test")

			expect(getStateCallback().value).to.equal(0)

			setStateCallback(function(state, props)
				expect(state).to.equal(getStateCallback())
				expect(props).to.equal(getPropsCallback())

				return {
					value = state.value + 1
				}
			end)

			expect(getStateCallback().value).to.equal(1)

			noopReconciler.unmountVirtualNode(instance)
		end)

		it("should cancel rendering if the function returns nil", function()
			local TestComponent = Component:extend("TestComponent")
			local setStateCallback
			local renderCount = 0

			function TestComponent:init()
				setStateCallback = function(newState)
					self:setState(newState)
				end

				self:setState({
					value = 0
				})
			end

			function TestComponent:render()
				renderCount = renderCount + 1
				return nil
			end

			local element = createElement(TestComponent)
			local instance = noopReconciler.mountVirtualNode(element, nil, "Test")
			expect(renderCount).to.equal(1)

			setStateCallback(function(state, props)
				return nil
			end)

			expect(renderCount).to.equal(1)

			noopReconciler.unmountVirtualNode(instance)
		end)
	end)

	describe("setState suspension", function()
		it("should defer setState triggered while reconciling", function()
			local Child = Component:extend("Child")
			local getParentStateCallback

			function Child:render()
				return nil
			end

			function Child:didMount()
				self.props.callback()
			end

			local Parent = Component:extend("Parent")

			function Parent:init()
				getParentStateCallback = function()
					return self.state
				end
			end

			function Parent:render()
				return createElement(Child, {
					callback = function()
						self:setState({
							foo = "bar"
						})
					end,
				})
			end

			local element = createElement(Parent)
			local hostParent = nil
			local key = "Test"

			local result = noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(result).to.be.ok()
			expect(getParentStateCallback().foo).to.equal("bar")
		end)

		it("should defer setState triggered while reconciling during an update", function()
			local Child = Component:extend("Child")
			local getParentStateCallback

			function Child:render()
				return nil
			end

			function Child:didUpdate()
				self.props.callback()
			end

			local Parent = Component:extend("Parent")

			function Parent:init()
				getParentStateCallback = function()
					return self.state
				end
			end

			function Parent:render()
				return createElement(Child, {
					callback = function()
						-- This guards against a stack overflow that would be OUR fault
						if not self.state.foo then
							self:setState({
								foo = "bar"
							})
						end
					end,
				})
			end

			local element = createElement(Parent)
			local hostParent = nil
			local key = "Test"

			local result = noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(result).to.be.ok()
			expect(getParentStateCallback().foo).to.equal(nil)

			result = noopReconciler.updateVirtualNode(result, createElement(Parent))

			expect(result).to.be.ok()
			expect(getParentStateCallback().foo).to.equal("bar")

			noopReconciler.unmountVirtualNode(result)
		end)
	end)
end
