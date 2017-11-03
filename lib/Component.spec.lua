return function()
	local Core = require(script.Parent.Core)
	local Reconciler = require(script.Parent.Reconciler)
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

	it("should throw on render by default", function()
		local MyComponent = Component:extend("Foo")

		local instance = MyComponent._new({})

		expect(instance).to.be.ok()

		expect(function()
			instance:render()
		end).to.throw()
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

		local instance = Reconciler.reify(Core.createElement(MyComponent))

		expect(mounts).to.equal(1)
		expect(unmounts).to.equal(0)

		Reconciler.teardown(instance)

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
			return Core.createElement(Child, {
				value = self.state.value,
			})
		end

		local element = Core.createElement(Container)
		local instance = Reconciler.reify(element)

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

		Reconciler.teardown(instance)
	end)
end