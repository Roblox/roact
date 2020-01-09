return function()
	local createContext = require(script.Parent.createContext)
	local createElement = require(script.Parent.createElement)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local createReconciler = require(script.Parent.createReconciler)
	local Component = require(script.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should return a new Context", function()
		local context = createContext("Test")
		expect(context).to.be.ok()
		expect(type(context)).to.equal("table")
	end)

	it("should be able to set a displayName", function()
		local context = createContext("Test")
		context.displayName = "Test"
		expect(tostring(context)).to.equal("Test")
	end)

	it("should be printable if no displayName is set", function()
		local context = createContext("Test")
		expect(tostring(context)).to.equal("Context")
	end)

	it("should have a unique key", function()
		local context = createContext("Test")
		local context2 = createContext("Test")
		expect(context.key).never.to.equal(context2.key)
	end)

	describe("getValue", function()
		it("should return the current value", function()
			local context = createContext("DefaultValue")
			expect(context:getValue()).to.equal("DefaultValue")
		end)
	end)

	describe("update", function()
		it("should update the current value", function()
			local context = createContext("DefaultValue")
			context:update("NewValue")
			expect(context:getValue()).to.equal("NewValue")
		end)

		it("should fire the update signal", function()
			local fired = false
			local context = createContext("DefaultValue")

			context.updateSignal:subscribe(function()
				fired = true
			end)

			context:update("NewValue")

			expect(fired).to.equal(true)
		end)
	end)

	describe("createProvider", function()
		it("should create a Provider above the given root", function()
			local foundValue
			local context = createContext("Test")

			local Listener = Component:extend("Listener")

			function Listener:render()
				foundValue = self._context[context.key]
			end

			local root = createElement(Listener)
			local newRoot = context:createProvider(root)

			local tree = noopReconciler.mountVirtualTree(newRoot, nil, "Provider Tree")

			expect(foundValue).to.be.ok()
			expect(foundValue:getValue()).to.equal("Test")

			noopReconciler.unmountVirtualTree(tree)
		end)
	end)
end
