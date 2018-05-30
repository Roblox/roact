return function()
	local Core = require(script.Parent.Core)
	local createElement = require(script.Parent.createElement)
	local Reconciler = require(script.Parent.Reconciler)
	local GlobalConfig = require(script.Parent.GlobalConfig)

	local Component = require(script.Parent.Component)

	it("should be extendable", function()
		local MyComponent = Component:extend("The Senate")

		expect(MyComponent).to.be.ok()
		expect(MyComponent._new).to.be.ok()
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
		local MyComponent = Component:extend("Foo")

		local instance = MyComponent._new({})

		expect(instance).to.be.ok()

		local ok, err = pcall(function()
			instance:render()
		end)

		expect(ok).to.equal(false)
		expect(err:find("Foo")).to.be.ok()
	end)

	it("should pass props to the initializer", function()
		local MyComponent = Component:extend("Wazo")

		local callCount = 0
		local testProps = {}

		function MyComponent:init(props)
			expect(props).to.equal(testProps)
			callCount = callCount + 1
		end

		MyComponent._new(testProps)

		expect(callCount).to.equal(1)
	end)

	it("should fire didMount and willUnmount when reified", function()
		local MyComponent = Component:extend("MyComponent")
		local mounts = 0
		local unmounts = 0

		function MyComponent:render()
			return nil
		end

		function MyComponent:didMount()
			mounts = mounts + 1
		end

		function MyComponent:willUnmount()
			unmounts = unmounts + 1
		end

		expect(mounts).to.equal(0)
		expect(unmounts).to.equal(0)

		local instance = Reconciler.mount(createElement(MyComponent))

		expect(mounts).to.equal(1)
		expect(unmounts).to.equal(0)

		Reconciler.unmount(instance)

		expect(mounts).to.equal(1)
		expect(unmounts).to.equal(1)
	end)

	it("should provide the proper arguments to willUpdate and didUpdate", function()
		local willUpdateCount = 0
		local didUpdateCount = 0
		local prevProps
		local prevState
		local nextProps
		local nextState
		local setValue

		local Child = Component:extend("PureChild")

		function Child:willUpdate(newProps, newState)
			nextProps = assert(newProps)
			nextState = assert(newState)
			prevProps = assert(self.props)
			prevState = assert(self.state)
			willUpdateCount = willUpdateCount + 1
		end

		function Child:didUpdate(oldProps, oldState)
			assert(oldProps)
			assert(oldState)
			expect(prevProps.value).to.equal(oldProps.value)
			expect(prevState.value).to.equal(oldState.value)
			expect(nextProps.value).to.equal(self.props.value)
			expect(nextState.value).to.equal(self.state.value)
			didUpdateCount = didUpdateCount + 1
		end

		function Child:render()
			return nil
		end

		local Container = Component:extend("Container")

		function Container:init()
			self.state = {
				value = 0,
			}
		end

		function Container:didMount()
			setValue = function(value)
				self:setState({
					value = value,
				})
			end
		end

		function Container:willUnmount()
			setValue = nil
		end

		function Container:render()
			return createElement(Child, {
				value = self.state.value,
			})
		end

		local element = createElement(Container)
		local instance = Reconciler.mount(element)

		expect(willUpdateCount).to.equal(0)
		expect(didUpdateCount).to.equal(0)

		setValue(1)

		expect(willUpdateCount).to.equal(1)
		expect(didUpdateCount).to.equal(1)

		setValue(1)

		expect(willUpdateCount).to.equal(2)
		expect(didUpdateCount).to.equal(2)

		setValue(2)

		expect(willUpdateCount).to.equal(3)
		expect(didUpdateCount).to.equal(3)

		setValue(1)

		expect(willUpdateCount).to.equal(4)
		expect(didUpdateCount).to.equal(4)

		Reconciler.unmount(instance)
	end)

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

		local handle = Reconciler.mount(createElement(TestComponent))

		expect(lastProps).to.be.a("table")
		expect(lastProps.foo).to.equal("hello")
		expect(lastProps.bar).to.equal("world")

		Reconciler.unmount(handle)

		lastProps = nil
		handle = Reconciler.mount(createElement(TestComponent, {
			foo = 5,
		}))

		expect(lastProps).to.be.a("table")
		expect(lastProps.foo).to.equal(5)
		expect(lastProps.bar).to.equal("world")

		Reconciler.unmount(handle)

		lastProps = nil
		handle = Reconciler.mount(createElement(TestComponent, {
			bar = false,
		}))

		expect(lastProps).to.be.a("table")
		expect(lastProps.foo).to.equal("hello")
		expect(lastProps.bar).to.equal(false)

		Reconciler.unmount(handle)
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

		local handle = Reconciler.mount(createElement(TestComponent, {
			foo = "hey"
		}))

		expect(lastProps).to.be.a("table")
		expect(lastProps.foo).to.equal("hey")
		expect(lastProps.bar).to.equal("world")

		handle = Reconciler.reconcile(handle, createElement(TestComponent))

		expect(lastProps).to.be.a("table")
		expect(lastProps.foo).to.equal("hello")
		expect(lastProps.bar).to.equal("world")

		Reconciler.unmount(handle)
	end)

	describe("setState", function()
		it("should throw when called in init", function()
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

		it("should throw when called in render", function()
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

		it("should throw when called in shouldUpdate", function()
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

		it("should throw when called in willUpdate", function()
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
			local instance = Reconciler.mount(element)

			expect(function()
				Reconciler.unmount(instance)
			end).to.throw()
		end)

		it("should remove values from state when the value is Core.None", function()
			local TestComponent = Component:extend("TestComponent")
			local setStateCallback, getStateCallback

			function TestComponent:init()
				setStateCallback = function(newState)
					self:setState(newState)
				end

				getStateCallback = function()
					return self.state
				end

				self.state = {
					value = 0
				}
			end

			function TestComponent:render()
				return nil
			end

			local element = createElement(TestComponent)
			local instance = Reconciler.mount(element)

			expect(getStateCallback().value).to.equal(0)

			setStateCallback({
				value = Core.None
			})

			expect(getStateCallback().value).to.equal(nil)

			Reconciler.unmount(instance)
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

				self.state = {
					value = 0
				}
			end

			function TestComponent:render()
				return nil
			end

			local element = createElement(TestComponent)
			local instance = Reconciler.mount(element)

			expect(getStateCallback().value).to.equal(0)

			setStateCallback(function(state, props)
				expect(state).to.equal(getStateCallback())
				expect(props).to.equal(getPropsCallback())

				return {
					value = state.value + 1
				}
			end)

			expect(getStateCallback().value).to.equal(1)

			Reconciler.unmount(instance)
		end)

		it("should cancel rendering if the function returns nil", function()
			local TestComponent = Component:extend("TestComponent")
			local setStateCallback
			local renderCount = 0

			function TestComponent:init()
				setStateCallback = function(newState)
					self:setState(newState)
				end

				self.state = {
					value = 0
				}
			end

			function TestComponent:render()
				renderCount = renderCount + 1
				return nil
			end

			local element = createElement(TestComponent)
			local instance = Reconciler.mount(element)
			expect(renderCount).to.equal(1)

			setStateCallback(function(state, props)
				return nil
			end)

			expect(renderCount).to.equal(1)

			Reconciler.unmount(instance)
		end)

		it("should not call getDerivedStateFromProps on setState", function()
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
		it("should return stack traces", function()
			local stackTraceCallback = nil

			GlobalConfig.set({
				elementTracing = true
			})

			local TestComponent = Component:extend("TestComponent")

			function TestComponent:init()
				stackTraceCallback = function()
					return self:getElementTraceback()
				end
			end

			function TestComponent:render()
				return createElement("StringValue")
			end

			local handle = Reconciler.mount(createElement(TestComponent))
			expect(stackTraceCallback()).to.be.ok()
			Reconciler.unmount(handle)
			GlobalConfig.reset()
		end)

		it("should return nil when elementTracing is off", function()
			local stackTraceCallback = nil

			local TestComponent = Component:extend("TestComponent")

			function TestComponent:init()
				stackTraceCallback = function()
					return self:getElementTraceback()
				end
			end

			function TestComponent:render()
				return createElement("StringValue")
			end

			local handle = Reconciler.mount(createElement(TestComponent))
			expect(stackTraceCallback()).to.never.be.ok()
			Reconciler.unmount(handle)
		end)
	end)
end
