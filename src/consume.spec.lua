return function()
	local consume = require(script.Parent.consume)
	local provide = require(script.Parent.provide)
	local createContext = require(script.Parent.createContext)
	local createElement = require(script.Parent.createElement)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local createReconciler = require(script.Parent.createReconciler)
	local Component = require(script.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should expect a table", function()
		expect(function()
			consume()
		end).to.throw()
	end)

	it("should return a function", function()
		expect(type(consume({}))).to.equal("function")
	end)

	it("should expect a Component in the returned function", function()
		expect(function()
			consume({})()
		end).to.throw()
	end)

	it("should expect all table values to be Contexts", function()
		local Listener = Component:extend("Listener")

		function Listener:render()
			return nil
		end

		Listener = consume({
			Context = {},
		})(Listener)

		local root = createElement(Listener)

		expect(function()
			local tree = noopReconciler.mountVirtualTree(root, nil, "Provider Tree")
			noopReconciler.unmountVirtualTree(tree)
		end).to.throw()
	end)

	it("should expect all Contexts in the table to be provided", function()
		local context = createContext("Test")

		local Listener = Component:extend("Listener")

		function Listener:render()
			return nil
		end

		Listener = consume({
			Context = context,
		})(Listener)

		local root = createElement(Listener)

		expect(function()
			local tree = noopReconciler.mountVirtualTree(root, nil, "Provider Tree")
			noopReconciler.unmountVirtualTree(tree)
		end).to.throw()
	end)

	it("should pass items into props according to the table", function()
		local foundContext = false
		local context = createContext("Test")
		local context2 = createContext("Test")

		local Listener = Component:extend("Listener")

		function Listener:render()
			local props = self.props
			local contextProp = props.Context
			local context2Prop = props.Context2
			if contextProp and context2Prop then
				foundContext = true
			end
		end

		Listener = consume({
			Context = context,
			Context2 = context2,
		})(Listener)

		local root = provide({context, context2}, {
			Listener = createElement(Listener),
		})

		local tree = noopReconciler.mountVirtualTree(root, nil, "Provider Tree")
		noopReconciler.unmountVirtualTree(tree)

		expect(foundContext).to.equal(true)
	end)

	it("should update when any consumed Context updates", function()
		local updateCount = 0

		local context = createContext("DefaultValue")
		local context2 = createContext("DefaultValue")

		local Listener = Component:extend("Listener")

		function Listener:render()
			return nil
		end

		function Listener:didUpdate()
			updateCount = updateCount + 1
		end

		Listener = consume({
			Context = context,
			Context2 = context2,
		})(Listener)

		local root = provide({context, context2}, {
			Listener = createElement(Listener),
		})

		local tree = noopReconciler.mountVirtualTree(root, nil, "Provider Tree")

		expect(updateCount).to.equal(0)

		context:update("NewValue")
		expect(updateCount).to.equal(1)

		context2:update("NewValue")
		expect(updateCount).to.equal(2)

		noopReconciler.unmountVirtualTree(tree)
	end)

	it("should pass props through to the wrapped Component", function()
		local updateCount = 0
		local value

		local context = createContext("DefaultValue")

		local Listener = Component:extend("Listener")

		function Listener:render()
			value = self.props.Value
			return nil
		end

		function Listener:didUpdate()
			updateCount = updateCount + 1
		end

		Listener = consume({
			Context = context,
		})(Listener)

		local root = provide({context}, {
			Listener = createElement(Listener, {
				Value = "First",
			}),
		})

		local tree = noopReconciler.mountVirtualTree(root, nil, "Provider Tree")

		expect(updateCount).to.equal(0)
		expect(value).to.equal("First")

		noopReconciler.updateVirtualTree(tree, provide({context}, {
			Listener = createElement(Listener, {
				Value = "Second",
			}),
		}))

		expect(updateCount).to.equal(1)
		expect(value).to.equal("Second")

		noopReconciler.unmountVirtualTree(tree)
	end)
end
