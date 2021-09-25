return function()
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local GlobalConfig = require(script.Parent.Parent.GlobalConfig)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should return stack traces in initial renders", function()
		local TestComponent = Component:extend("TestComponent")

		local stackTrace
		function TestComponent:init()
			stackTrace = self:getElementTraceback()
		end

		function TestComponent:render()
			return nil
		end

		local config = {
			elementTracing = true,
		}

		GlobalConfig.scoped(config, function()
			local element = createElement(TestComponent)
			local hostParent = nil
			local key = "Some key"

			noopReconciler.mountVirtualNode(element, hostParent, key)
		end)

		expect(stackTrace).to.be.a("string")
	end)

	itSKIP("it should return an updated stack trace after an update", function() end)

	it("should return nil when elementTracing is off", function()
		local stackTrace = nil

		local config = {
			elementTracing = false,
		}

		local TestComponent = Component:extend("TestComponent")

		function TestComponent:init()
			stackTrace = self:getElementTraceback()
		end

		function TestComponent:render()
			return nil
		end

		GlobalConfig.scoped(config, function()
			local element = createElement(TestComponent)
			local hostParent = nil
			local key = "Some key"

			noopReconciler.mountVirtualNode(element, hostParent, key)
		end)

		expect(stackTrace).to.equal(nil)
	end)
end
