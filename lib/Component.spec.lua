return function()
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local GlobalConfig = require(script.Parent.GlobalConfig)
	local None = require(script.Parent.None)
	local NoopRenderer = require(script.Parent.NoopRenderer)

	local Component = require(script.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	itSKIP("should invoke shouldUpdate when props update", function()
		-- TODO
	end)

	itSKIP("should invoke shouldUpdate when state updates", function()
		-- TODO
	end)

	describe("getDerivedStateFromProps", function()
		SKIP()

		-- TODO

		-- it("should call getDerivedStateFromProps appropriately", function()
		-- 	local TestComponent = Component:extend("TestComponent")
		-- 	local getStateCallback

		-- 	function TestComponent.getDerivedStateFromProps(newProps, oldState)
		-- 		return {
		-- 			visible = newProps.visible
		-- 		}
		-- 	end

		-- 	function TestComponent:init(props)
		-- 		self.state = {
		-- 			visible = false
		-- 		}

		-- 		getStateCallback = function()
		-- 			return self.state
		-- 		end
		-- 	end

		-- 	function TestComponent:render() end

		-- 	local handle = Reconciler.mount(createElement(TestComponent, {
		-- 		visible = true
		-- 	}))

		-- 	local state = getStateCallback()
		-- 	expect(state.visible).to.equal(true)

		-- 	handle = Reconciler.reconcile(handle, createElement(TestComponent, {
		-- 		visible = 123
		-- 	}))

		-- 	state = getStateCallback()
		-- 	expect(state.visible).to.equal(123)

		-- 	Reconciler.unmount(handle)
		-- end)
	end)

	describe("defaultProps", function()
		it("should pull values from defaultProps where appropriate", function()
			local lastProps
			local TestComponent = Component:extend("TestComponent")

			TestComponent.defaultProps = {
				foo = "hello",
				bar = "world",
			}

			function TestComponent:render()
				lastProps = self.props
				return nil
			end

			local handle = noopReconciler.mountNode(createElement(TestComponent), nil, "Test")

			expect(lastProps).to.be.a("table")
			expect(lastProps.foo).to.equal("hello")
			expect(lastProps.bar).to.equal("world")

			noopReconciler.unmountNode(handle)

			lastProps = nil
			local tree = createElement(TestComponent, { foo = 5 })
			handle = noopReconciler.mountNode(tree, nil, "Test")

			expect(lastProps).to.be.a("table")
			expect(lastProps.foo).to.equal(5)
			expect(lastProps.bar).to.equal("world")

			noopReconciler.unmountNode(handle)

			lastProps = nil
			tree = createElement(TestComponent, {
				bar = false,
			})
			handle = noopReconciler.mountNode(tree, nil, "Test")

			expect(lastProps).to.be.a("table")
			expect(lastProps.foo).to.equal("hello")
			expect(lastProps.bar).to.equal(false)

			noopReconciler.unmountNode(handle)
		end)

		it("should include defaultProps in props passed to shouldUpdate", function()
			local lastProps
			local TestComponent = Component:extend("TestComponent")

			TestComponent.defaultProps = {
				foo = "hello",
				bar = "world",
			}

			function TestComponent:willUpdate(newProps)
				lastProps = newProps
			end

			function TestComponent:render()
				return nil
			end

			local tree = createElement(TestComponent, {})
			local handle = noopReconciler.mountNode(tree, nil, "Test")
			noopReconciler.updateNode(handle, createElement(TestComponent, {
				baz = "!",
			}))

			expect(lastProps).to.be.a("table")
			expect(lastProps.foo).to.equal("hello")
			expect(lastProps.bar).to.equal("world")
			expect(lastProps.baz).to.equal("!")

			noopReconciler.unmountNode(handle)
		end)

		it("should fall back to defaultProps correctly after an update", function()
			local lastProps
			local TestComponent = Component:extend("TestComponent")

			TestComponent.defaultProps = {
				foo = "hello",
				bar = "world",
			}

			function TestComponent:render()
				lastProps = self.props
				return nil
			end

			local tree = createElement(TestComponent, { foo = "hey" })
			local handle = noopReconciler.mountNode(tree, nil, "Test")

			expect(lastProps).to.be.a("table")
			expect(lastProps.foo).to.equal("hey")
			expect(lastProps.bar).to.equal("world")

			handle = noopReconciler.updateNode(handle, createElement(TestComponent))

			expect(lastProps).to.be.a("table")
			expect(lastProps.foo).to.equal("hello")
			expect(lastProps.bar).to.equal("world")

			noopReconciler.unmountNode(handle)
		end)

		it("should pass defaultProps in init and first getDerivedStateFromProps", function()
			local derivedProps = nil
			local initProps = nil
			local initSelfProps = nil

			local TestComponent = Component:extend("TestComponent")

			TestComponent.defaultProps = {
				heyNow = "get your game on",
			}

			function TestComponent:init(props)
				initProps = props
				initSelfProps = self.props
			end

			function TestComponent:render()
				return nil
			end

			function TestComponent.getDerivedStateFromProps(nextProps, lastState)
				derivedProps = nextProps
			end

			local tree = createElement(TestComponent)
			local handle = noopReconciler.mountNode(tree, nil, "Test")

			expect(derivedProps).to.be.ok()
			expect(initProps).to.be.ok()
			expect(initSelfProps).to.be.ok()

			expect(derivedProps.heyNow).to.equal(TestComponent.defaultProps.heyNow)
			expect(initProps.heyNow).to.equal(TestComponent.defaultProps.heyNow)

			expect(initProps).to.equal(initSelfProps)

			noopReconciler.unmountNode(handle)
		end)
	end)

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
			local instance = noopReconciler.mountNode(element, nil, "Test")

			expect(getStateCallback().value).to.equal(0)

			setStateCallback({
				value = None
			})

			expect(getStateCallback().value).to.equal(nil)

			noopReconciler.unmountNode(instance)
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
			local instance = noopReconciler.mountNode(element, nil, "Test")

			expect(getStateCallback().value).to.equal(0)

			setStateCallback(function(state, props)
				expect(state).to.equal(getStateCallback())
				expect(props).to.equal(getPropsCallback())

				return {
					value = state.value + 1
				}
			end)

			expect(getStateCallback().value).to.equal(1)

			noopReconciler.unmountNode(instance)
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
			local instance = noopReconciler.mountNode(element, nil, "Test")
			expect(renderCount).to.equal(1)

			setStateCallback(function(state, props)
				return nil
			end)

			expect(renderCount).to.equal(1)

			noopReconciler.unmountNode(instance)
		end)
	end)

	describe("getElementTraceback", function()
		it("should return stack traces in initial renders", function()
			local stackTrace = nil

			local config = {
				elementTracing = true,
			}

			GlobalConfig.scoped(config, function()
				local TestComponent = Component:extend("TestComponent")

				function TestComponent:init()
					stackTrace = self:getElementTraceback()
				end

				function TestComponent:render()
					return nil
				end

				local element = createElement(TestComponent)
				local hostParent = nil
				local key = "Some key"
				noopReconciler.mountNode(element, hostParent, key)
			end)

			expect(stackTrace).to.be.a("string")
		end)

		-- TODO: it should return an updated stack trace after an update

		it("should return nil when elementTracing is off", function()
			local stackTrace = nil

			local config = {
				elementTracing = false,
			}

			GlobalConfig.scoped(config, function()
				local TestComponent = Component:extend("TestComponent")

				function TestComponent:init()
					stackTrace = self:getElementTraceback()
				end

				function TestComponent:render()
					return nil
				end

				local element = createElement(TestComponent)
				local hostParent = nil
				local key = "Some key"
				noopReconciler.mountNode(element, hostParent, key)
			end)

			expect(stackTrace).to.equal(nil)
		end)
	end)
end
