return function()
	local createContext = require(script.Parent.createContext)
	local createElement = require(script.Parent.createElement)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local createReconciler = require(script.Parent.createReconciler)
	local PureComponent = require(script.Parent.PureComponent)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should return a table", function()
		local context = createContext("Test")
		expect(context).to.be.ok()
		expect(type(context)).to.equal("table")
	end)

	it("should contain a Provider and a Consumer", function()
		local context = createContext("Test")
		expect(context.Provider).to.be.ok()
		expect(context.Consumer).to.be.ok()
	end)

	describe("Provider", function()
		it("should render its child component", function()
			local didRender = false
			local context = createContext("Test")

			local Listener = PureComponent:extend("Listener")

			function Listener:render()
				didRender = true
			end

			local element = createElement(context.Provider, {
				value = "Test",
			}, {
				Listener = createElement(Listener),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)

			expect(didRender).to.equal(true)
		end)

		it("should expect one child", function()
			local context = createContext("Test")

			local Listener = PureComponent:extend("Listener")

			function Listener:render()
				return nil
			end

			local element = createElement(context.Provider, {
				value = "Test",
			}, {
				Listener = createElement(Listener),
				Listener2 = createElement(Listener),
			})

			expect(function()
				local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
				noopReconciler.unmountVirtualTree(tree)
			end).to.throw()
		end)
	end)

	describe("Consumer", function()
		it("should expect a render function", function()
			local context = createContext("Test")

			local Listener = PureComponent:extend("Listener")

			function Listener:render()
				return nil
			end

			local element = createElement(context.Consumer)

			expect(function()
				local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
				noopReconciler.unmountVirtualTree(tree)
			end).to.throw()
		end)

		it("should return the default value if there is no Provider", function()
			local foundValue
			local context = createContext("Test")

			local element = createElement(context.Consumer, {
				render = function(value)
					foundValue = value
				end,
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)

			expect(foundValue).to.equal("Test")
		end)

		it("should pass the value to the render function", function()
			local foundValue
			local context = createContext("Test")

			local Listener = PureComponent:extend("Listener")

			function Listener:render()
				return createElement(context.Consumer, {
					render = function(value)
						foundValue = value
					end,
				})
			end

			local element = createElement(context.Provider, {
				value = "NewTest",
			}, {
				Listener = createElement(Listener),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)

			expect(foundValue).to.equal("NewTest")
		end)

		it("should update when the value updates", function()
			local renderCount = 0
			local foundValue

			local context = createContext("Test")

			local Listener = PureComponent:extend("Listener")

			function Listener:render()
				return createElement(context.Consumer, {
					render = function(value)
						renderCount = renderCount + 1
						foundValue = value
					end,
				})
			end

			local element = createElement(context.Provider, {
				value = "NewTest",
			}, {
				Listener = createElement(Listener),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")

			expect(renderCount).to.equal(1)
			expect(foundValue).to.equal("NewTest")

			noopReconciler.updateVirtualTree(tree, createElement(context.Provider, {
				value = "ThirdTest",
			}, {
				Listener = createElement(Listener),
			}))

			expect(renderCount).to.equal(2)
			expect(foundValue).to.equal("ThirdTest")

			noopReconciler.unmountVirtualTree(tree)
		end)
	end)
end
