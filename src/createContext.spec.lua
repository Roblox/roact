return function()
	local createContext = require(script.Parent.createContext)
	local createElement = require(script.Parent.createElement)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local createReconciler = require(script.Parent.createReconciler)
	local createSpy = require(script.Parent.createSpy)

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
		it("should render its children", function()
			local context = createContext("Test")

			local Listener = createSpy(function()
				return nil
			end)

			local element = createElement(context.Provider, {
				value = "Test",
			}, {
				Listener = createElement(Listener.value),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)

			expect(Listener.callCount).to.equal(1)
		end)
	end)

	describe("Consumer", function()
		it("should expect a render function", function()
			local context = createContext("Test")
			local element = createElement(context.Consumer)

			expect(function()
				noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			end).to.throw()
		end)

		it("should return the default value if there is no Provider", function()
			local valueSpy = createSpy()
			local context = createContext("Test")

			local element = createElement(context.Consumer, {
				render = valueSpy.value,
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)

			valueSpy:assertCalledWith("Test")
		end)

		it("should pass the value to the render function", function()
			local valueSpy = createSpy()
			local context = createContext("Test")

			local function Listener()
				return createElement(context.Consumer, {
					render = valueSpy.value,
				})
			end

			local element = createElement(context.Provider, {
				value = "NewTest",
			}, {
				Listener = createElement(Listener),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)

			valueSpy:assertCalledWith("NewTest")
		end)

		it("should update when the value updates", function()
			local valueSpy = createSpy()
			local context = createContext("Test")

			local function Listener()
				return createElement(context.Consumer, {
					render = valueSpy.value,
				})
			end

			local element = createElement(context.Provider, {
				value = "NewTest",
			}, {
				Listener = createElement(Listener),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")

			expect(valueSpy.callCount).to.equal(1)
			valueSpy:assertCalledWith("NewTest")

			noopReconciler.updateVirtualTree(tree, createElement(context.Provider, {
				value = "ThirdTest",
			}, {
				Listener = createElement(Listener),
			}))

			expect(valueSpy.callCount).to.equal(3)
			valueSpy:assertCalledWith("ThirdTest")

			noopReconciler.unmountVirtualTree(tree)
		end)
	end)
end
