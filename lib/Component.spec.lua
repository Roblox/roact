return function()
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local createSpy = require(script.Parent.createSpy)
	local GlobalConfig = require(script.Parent.GlobalConfig)
	local None = require(script.Parent.None)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local Type = require(script.Parent.Type)

	local Component = require(script.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be extendable", function()
		local MyComponent = Component:extend("The Senate")

		expect(MyComponent).to.be.ok()
		expect(Type.of(MyComponent)).to.equal(Type.StatefulComponentClass)
	end)

	it("should prevent extending a user component", function()
		local MyComponent = Component:extend("Sheev")

		expect(function()
			MyComponent:extend("Frank")
		end).to.throw()
	end)

	it("should use a given name", function()
		local MyComponent = Component:extend("FooBar")

		local name = tostring(MyComponent)

		expect(name).to.be.a("string")
		expect(name:find("FooBar")).to.be.ok()
	end)

	it("should throw on render with a useful message by default", function()
		local MyComponent = Component:extend("MyComponent")

		local element = createElement(MyComponent)
		local hostParent = nil
		local key = "Some Component Key"

		local success, result = pcall(function()
			noopReconciler.mountNode(element, hostParent, key)
		end)

		expect(success).to.equal(false)
		expect(result:match("MyComponent")).to.be.ok()
		expect(result:match("render")).to.be.ok()
	end)

	it("should pass props to the initializer", function()
		local MyComponent = Component:extend("MyComponent")

		local initSpy = createSpy(function(props)
			return nil
		end)

		MyComponent.init = initSpy.value

		function MyComponent:render()
			return nil
		end

		local props = {
			a = 5,
		}
		local element = createElement(MyComponent, props)
		local hostParent = nil
		local key = "Some Component Key"

		local node = noopReconciler.mountNode(element, hostParent, key)

		expect(Type.of(node)).to.equal(Type.Node)

		expect(initSpy.callCount).to.equal(1)

		local initValues = initSpy:captureValues("instance", "props")

		expect(Type.of(initValues.instance)).to.equal(Type.StatefulComponentInstance)
		expect(typeof(initValues.props)).to.equal("table")
		expect(initValues.props.a).to.equal(props.a)
	end)

	it("should fire didMount and willUnmount when mounted and unmounted", function()
		local MyComponent = Component:extend("MyComponent")

		function MyComponent:render()
			return nil
		end

		local didMountSpy = createSpy()
		local willUnmountSpy = createSpy()

		MyComponent.didMount = didMountSpy.value
		MyComponent.willUnmount = willUnmountSpy.value

		expect(didMountSpy.callCount).to.equal(0)
		expect(willUnmountSpy.callCount).to.equal(0)

		local hostParent = nil
		local key = "Some Key"
		local element = createElement(MyComponent)
		local node = noopReconciler.mountNode(element, hostParent, key)

		expect(didMountSpy.callCount).to.equal(1)
		expect(willUnmountSpy.callCount).to.equal(0)

		noopReconciler.unmountNode(node)

		expect(didMountSpy.callCount).to.equal(1)
		expect(willUnmountSpy.callCount).to.equal(1)

		local didMountValues = didMountSpy:captureValues("instance")
		local willUnmountValues = willUnmountSpy:captureValues("instance")

		expect(Type.of(didMountValues.instance)).to.equal(Type.StatefulComponentInstance)

		expect(Type.of(willUnmountValues.instance)).to.equal(Type.StatefulComponentInstance)

		expect(didMountValues.instance).to.equal(willUnmountValues.instance)
	end)

	it("should invoke willUpdate and didUpdate when props update", function()
		local MyComponent = Component:extend("MyComponent")

		local willUpdateProps
		local willUpdateState

		local didUpdateProps
		local didUpdateState

		local willUpdateSpy = createSpy(function(self)
			willUpdateProps = self.props
			willUpdateState = self.state
		end)
		local didUpdateSpy = createSpy(function(self)
			didUpdateProps = self.props
			didUpdateState = self.state
		end)

		MyComponent.willUpdate = willUpdateSpy.value
		MyComponent.didUpdate = didUpdateSpy.value

		local stateValue = "some state value"

		function MyComponent:init()
			self.state = {
				value = stateValue,
			}
		end

		function MyComponent:render()
			return nil
		end

		local value = 3
		local element = createElement(MyComponent, {
			value = value,
		})
		local hostParent = nil
		local key = "Updates Are Cool"

		local node = noopReconciler.mountNode(element, hostParent, key)

		expect(willUpdateSpy.callCount).to.equal(0)
		expect(didUpdateSpy.callCount).to.equal(0)

		local newValue = 5
		local newElement = createElement(MyComponent, {
			value = newValue,
		})
		noopReconciler.updateNode(node, newElement)

		expect(willUpdateSpy.callCount).to.equal(1)
		expect(didUpdateSpy.callCount).to.equal(1)

		local willUpdateValues = willUpdateSpy:captureValues("instance", "newProps", "newState")

		expect(Type.of(willUpdateValues.instance)).to.equal(Type.StatefulComponentInstance)

		expect(willUpdateValues.newProps).to.be.a("table")
		expect(willUpdateValues.newProps.value).to.equal(newValue)

		expect(willUpdateValues.newState).to.be.a("table")
		expect(willUpdateValues.newState.value).to.equal(stateValue)

		expect(willUpdateProps).to.be.a("table")
		expect(willUpdateProps.value).to.equal(value)

		expect(willUpdateState).to.be.a("table")
		expect(willUpdateState.value).to.equal(stateValue)

		local didUpdateValues = didUpdateSpy:captureValues("instance", "oldProps", "oldState")

		expect(Type.of(didUpdateValues.instance)).to.equal(Type.StatefulComponentInstance)

		expect(didUpdateValues.oldProps).to.be.a("table")
		expect(didUpdateValues.oldProps.value).to.equal(value)

		expect(didUpdateValues.oldState).to.be.a("table")
		expect(didUpdateValues.oldState.value).to.equal(stateValue)

		expect(didUpdateProps).to.be.a("table")
		expect(didUpdateProps.value).to.equal(newValue)

		expect(didUpdateState).to.be.a("table")
		expect(didUpdateState.value).to.equal(stateValue)
	end)

	itSKIP("should invoke willUpdate and didUpdate when state updates", function()
		-- TODO
	end)

	itSKIP("should invoke shouldUpdate when props update", function()
		-- TODO
	end)

	itSKIP("should invoke shouldUpdate when state updates", function()
		-- TODO
	end)

	describe("getDerivedStateFromProps", function()
		SKIP()

		-- TODO

		it("should call getDerivedStateFromProps appropriately", function()
			local TestComponent = Component:extend("TestComponent")
			local getStateCallback

			function TestComponent.getDerivedStateFromProps(newProps, oldState)
				return {
					visible = newProps.visible
				}
			end

			function TestComponent:init(props)
				self.state = {
					visible = false
				}

				getStateCallback = function()
					return self.state
				end
			end

			function TestComponent:render() end

			local handle = Reconciler.mount(createElement(TestComponent, {
				visible = true
			}))

			local state = getStateCallback()
			expect(state.visible).to.equal(true)

			handle = Reconciler.reconcile(handle, createElement(TestComponent, {
				visible = 123
			}))

			state = getStateCallback()
			expect(state.visible).to.equal(123)

			Reconciler.unmount(handle)
		end)
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
		itSKIP("should throw when called in init", function()
			local InitComponent = Component:extend("InitComponent")

			function InitComponent:init()
				self:setState({
					a = 1
				})
			end

			function InitComponent:render()
				return nil
			end

			local initElement = createElement(InitComponent)

			expect(function()
				Reconciler.mount(initElement)
			end).to.throw()
		end)

		itSKIP("should throw when called in render", function()
			local RenderComponent = Component:extend("RenderComponent")

			function RenderComponent:render()
				self:setState({
					a = 1
				})
			end

			local renderElement = createElement(RenderComponent)

			expect(function()
				Reconciler.mount(renderElement)
			end).to.throw()
		end)

		itSKIP("should throw when called in shouldUpdate", function()
			local TestComponent = Component:extend("TestComponent")

			local triggerTest

			function TestComponent:init()
				triggerTest = function()
					self:setState({
						a = 1
					})
				end
			end

			function TestComponent:render()
				return nil
			end

			function TestComponent:shouldUpdate()
				self:setState({
					a = 1
				})
			end

			local testElement = createElement(TestComponent)

			expect(function()
				Reconciler.mount(testElement)
				triggerTest()
			end).to.throw()
		end)

		itSKIP("should throw when called in willUpdate", function()
			local TestComponent = Component:extend("TestComponent")
			local forceUpdate

			function TestComponent:init()
				forceUpdate = function()
					self:_forceUpdate()
				end
			end

			function TestComponent:render()
				return nil
			end

			function TestComponent:willUpdate()
				self:setState({
					a = 1
				})
			end

			local testElement = createElement(TestComponent)

			expect(function()
				Reconciler.mount(testElement)
				forceUpdate()
			end).to.throw()
		end)

		itSKIP("should throw when called in willUnmount", function()
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
			local instance = Reconciler.mount(element)

			expect(function()
				Reconciler.unmount(instance)
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

				-- TODO: Switch to setState once implemented
				self.state = {
					value = 0
				}
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

				-- TODO: Switch to setState when possible
				self.state = {
					value = 0
				}
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

				-- TODO: Use setState, again, once implemented
				self.state = {
					value = 0
				}
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

		-- TODO: It SHOULD call getDerivedStateFromProps
		itSKIP("should not call getDerivedStateFromProps on setState", function()
			local TestComponent = Component:extend("TestComponent")
			local setStateCallback
			local getDerivedStateFromPropsCount = 0

			function TestComponent:init()
				setStateCallback = function(newState)
					self:setState(newState)
				end

				self.state = {
					value = 0
				}
			end

			function TestComponent:render()
				return nil
			end

			function TestComponent.getDerivedStateFromProps(nextProps, lastState)
				getDerivedStateFromPropsCount = getDerivedStateFromPropsCount + 1
			end

			local element = createElement(TestComponent, {
				someProp = 1,
			})

			local instance = Reconciler.mount(element)
			expect(getDerivedStateFromPropsCount).to.equal(1)

			setStateCallback({
				value = 1,
			})
			expect(getDerivedStateFromPropsCount).to.equal(1)


			Reconciler.unmount(instance)
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
