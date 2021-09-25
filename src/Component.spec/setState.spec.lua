return function()
	local createElement = require(script.Parent.Parent.createElement)
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
					a = 1,
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
			local TestComponent = Component:extend("TestComponent")

			function TestComponent:render()
				self:setState({
					a = 1,
				})
			end

			local renderElement = createElement(TestComponent)

			local success, result = pcall(noopReconciler.mountVirtualTree, renderElement)

			expect(success).to.equal(false)
			expect(result:match("render")).to.be.ok()
			expect(result:match("TestComponent")).to.be.ok()
		end)

		it("should throw when called in shouldUpdate", function()
			local TestComponent = Component:extend("TestComponent")

			function TestComponent:render()
				return nil
			end

			function TestComponent:shouldUpdate()
				self:setState({
					a = 1,
				})
			end

			local initialElement = createElement(TestComponent)
			local updatedElement = createElement(TestComponent)

			local tree = noopReconciler.mountVirtualTree(initialElement)

			local success, result = pcall(noopReconciler.updateVirtualTree, tree, updatedElement)

			expect(success).to.equal(false)
			expect(result:match("shouldUpdate")).to.be.ok()
			expect(result:match("TestComponent")).to.be.ok()
		end)

		it("should throw when called in willUpdate", function()
			local TestComponent = Component:extend("TestComponent")

			function TestComponent:render()
				return nil
			end

			function TestComponent:willUpdate()
				self:setState({
					a = 1,
				})
			end

			local initialElement = createElement(TestComponent)
			local updatedElement = createElement(TestComponent)
			local tree = noopReconciler.mountVirtualTree(initialElement)

			local success, result = pcall(noopReconciler.updateVirtualTree, tree, updatedElement)

			expect(success).to.equal(false)
			expect(result:match("willUpdate")).to.be.ok()
			expect(result:match("TestComponent")).to.be.ok()
		end)

		it("should not throw when called in willUnmount", function()
			local TestComponent = Component:extend("TestComponent")

			function TestComponent:render()
				return nil
			end

			function TestComponent:willUnmount()
				self:setState({
					a = 1,
				})
			end

			local element = createElement(TestComponent)
			local tree = noopReconciler.mountVirtualTree(element)

			local success, _ = pcall(noopReconciler.unmountVirtualTree, tree)

			expect(success).to.equal(true)
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
					value = 0,
				})
			end

			function TestComponent:render()
				return nil
			end

			local element = createElement(TestComponent)
			local instance = noopReconciler.mountVirtualNode(element, nil, "Test")

			expect(getStateCallback().value).to.equal(0)

			setStateCallback({
				value = None,
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
					value = 0,
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
					value = state.value + 1,
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
					value = 0,
				})
			end

			function TestComponent:render()
				renderCount = renderCount + 1
				return nil
			end

			local element = createElement(TestComponent)
			local instance = noopReconciler.mountVirtualNode(element, nil, "Test")
			expect(renderCount).to.equal(1)

			setStateCallback(function(_state, _props)
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
							foo = "bar",
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
								foo = "bar",
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

		it("should combine pending state changes properly", function()
			local Child = Component:extend("Child")
			local getParentStateCallback

			function Child:render()
				return nil
			end

			function Child:didMount()
				self.props.callback("foo", 1)
				self.props.callback("bar", 3)
			end

			local Parent = Component:extend("Parent")

			function Parent:init()
				getParentStateCallback = function()
					return self.state
				end
			end

			function Parent:render()
				return createElement(Child, {
					callback = function(key, value)
						self:setState({
							[key] = value,
						})
					end,
				})
			end

			local element = createElement(Parent)
			local hostParent = nil
			local key = "Test"

			local result = noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(result).to.be.ok()
			expect(getParentStateCallback().foo).to.equal(1)
			expect(getParentStateCallback().bar).to.equal(3)

			noopReconciler.unmountVirtualNode(result)
		end)

		it("should abort properly when functional setState returns nil while deferred", function()
			local Child = Component:extend("Child")

			function Child:render()
				return nil
			end

			function Child:didMount()
				self.props.callback()
			end

			local Parent = Component:extend("Parent")

			local renderSpy = createSpy(function(self)
				return createElement(Child, {
					callback = function()
						self:setState(function()
							-- abort the setState
							return nil
						end)
					end,
				})
			end)

			Parent.render = renderSpy.value

			local element = createElement(Parent)
			local hostParent = nil
			local key = "Test"

			local result = noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(result).to.be.ok()
			expect(renderSpy.callCount).to.equal(1)

			noopReconciler.unmountVirtualNode(result)
		end)

		it("should still apply pending state if a subsequent state update was aborted", function()
			local Child = Component:extend("Child")
			local getParentStateCallback

			function Child:render()
				return nil
			end

			function Child:didMount()
				self.props.callback(function()
					return {
						foo = 1,
					}
				end)
				self.props.callback(function()
					return nil
				end)
			end

			local Parent = Component:extend("Parent")

			function Parent:init()
				getParentStateCallback = function()
					return self.state
				end
			end

			function Parent:render()
				return createElement(Child, {
					callback = function(stateUpdater)
						self:setState(stateUpdater)
					end,
				})
			end

			local element = createElement(Parent)
			local hostParent = nil
			local key = "Test"

			local result = noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(result).to.be.ok()
			expect(getParentStateCallback().foo).to.equal(1)

			noopReconciler.unmountVirtualNode(result)
		end)

		it("should not re-process new state when pending state is present after update", function()
			local setComponentState
			local getComponentState

			local MyComponent = Component:extend("MyComponent")

			function MyComponent:init()
				self:setState({
					hasUpdatedOnce = false,
					counter = 0,
				})

				setComponentState = function(mapState)
					self:setState(mapState)
				end

				getComponentState = function()
					return self.state
				end
			end

			function MyComponent:render()
				return nil
			end

			function MyComponent:didUpdate()
				if self.state.hasUpdatedOnce == false then
					self:setState({
						hasUpdatedOnce = true,
					})
				end
			end

			local element = createElement(MyComponent)
			local hostParent = nil
			local key = "Test"

			noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(getComponentState().hasUpdatedOnce).to.equal(false)
			expect(getComponentState().counter).to.equal(0)

			setComponentState(function(state)
				return {
					counter = state.counter + 1,
				}
			end)

			expect(getComponentState().hasUpdatedOnce).to.equal(true)
			expect(getComponentState().counter).to.equal(1)
		end)

		it("should throw when an infinite update is triggered", function()
			local InfiniteUpdater = Component:extend("InfiniteUpdater")

			function InfiniteUpdater:render()
				return nil
			end

			function InfiniteUpdater:didMount()
				self:setState({})
			end

			function InfiniteUpdater:didUpdate()
				self:setState({})
			end

			local element = createElement(InfiniteUpdater)
			local hostParent = nil
			local key = "Test"

			local success, result = pcall(noopReconciler.mountVirtualNode, element, hostParent, key)

			expect(success).to.equal(false)
			expect(result:find("InfiniteUpdater")).to.be.ok()
			expect(result:find("reached the setState update recursion limit")).to.be.ok()
		end)

		itSKIP("should process single updates with both new and pending state", function()
			--[[
				This situation shouldn't be possible currently, but the implementation
				should support it for future update de-duplication
			]]
		end)

		it("should call trigger update after didMount when setting state in didMount", function()
			--[[
				Before setState suspension, it was possible to call setState in didMount but it would
				not actually finish resolving didMount until after the entire update.

				This is theoretically problematic, as it means that lifecycle methods like didUpdate
				could be called before didMount is finished. setState suspension resolves this by
				suspending state updates made in didMount and didUpdate as well as reconciliation
			]]
			local MyComponent = Component:extend("MyComponent")

			function MyComponent:init()
				self:setState({
					status = "initial mount",
				})

				self.isMounted = false
			end

			function MyComponent:render()
				return nil
			end

			function MyComponent:didMount()
				self:setState({
					status = "mounted",
				})

				self.isMounted = true
			end

			function MyComponent:didUpdate(_oldProps, oldState)
				expect(oldState.status).to.equal("initial mount")
				expect(self.state.status).to.equal("mounted")

				expect(self.isMounted).to.equal(true)
			end

			local element = createElement(MyComponent)
			local hostParent = nil
			local key = "Test"

			local result = noopReconciler.mountVirtualNode(element, hostParent, key)

			expect(result).to.be.ok()
		end)
	end)
end
