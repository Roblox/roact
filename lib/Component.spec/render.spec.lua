return function()
	local createElement = require(script.Parent.Parent.createElement)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local createReconciler = require(script.Parent.Parent.createReconciler)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should throw on mount if not overridden", function()
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
end