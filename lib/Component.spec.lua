return function()
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local None = require(script.Parent.None)
	local NoopRenderer = require(script.Parent.NoopRenderer)

	local Component = require(script.Parent.Component)

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

			noopReconciler.mountTree(initElement)

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
				noopReconciler.mountTree(renderElement)
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

			local tree = noopReconciler.mountTree(initialElement)

			expect(function()
				noopReconciler.updateTree(tree, updatedElement)
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
			local tree = noopReconciler.mountTree(initialElement)

			expect(function()
				noopReconciler.updateTree(tree, updatedElement)
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
			local tree = noopReconciler.mountTree(element)

			expect(function()
				noopReconciler.unmountTree(tree)
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
end
