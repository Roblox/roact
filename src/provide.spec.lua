return function()
	local provide = require(script.Parent.provide)
	local createContext = require(script.Parent.createContext)
	local createElement = require(script.Parent.createElement)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local createReconciler = require(script.Parent.createReconciler)
	local Component = require(script.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should expect a Context list and Children table", function()
		expect(function()
			provide()
		end).to.throw()

		expect(function()
			provide({})
		end).to.throw()

		provide({}, {})
	end)

	it("should expect each entry to be a Context", function()
		local testTable = {}
		local element = provide({testTable}, {})

		expect(function()
			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)
		end).to.throw()
	end)

	it("should render the components in Children", function()
		local didRender = false

		local Listener = Component:extend("Listener")

		function Listener:render()
			didRender = true
		end

		local element = provide({}, {
			Listener = createElement(Listener),
		})

		local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
		noopReconciler.unmountVirtualTree(tree)

		expect(didRender).to.equal(true)
	end)

	it("should provide each Context to the context table", function()
		local foundContext = false

		local context = createContext("Test")
		local context2 = createContext("Test")

		local Listener = Component:extend("Listener")

		function Listener:render()
			if self._context[context.key] and self._context[context2.key] then
				foundContext = true
			end
		end

		local element = provide({context, context2}, {
			Listener = createElement(Listener),
		})

		local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
		noopReconciler.unmountVirtualTree(tree)

		expect(foundContext).to.equal(true)
	end)
end
