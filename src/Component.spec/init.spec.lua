return function()
	local assertDeepEqual = require(script.Parent.Parent.assertDeepEqual)
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local createSpy = require(script.Parent.Parent.createSpy)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local Type = require(script.Parent.Parent.Type)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be invoked with props when mounted", function()
		local MyComponent = Component:extend("MyComponent")

		local initSpy = createSpy()

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

		noopReconciler.mountVirtualNode(element, hostParent, key)

		expect(initSpy.callCount).to.equal(1)

		local values = initSpy:captureValues("self", "props")

		expect(Type.of(values.self)).to.equal(Type.StatefulComponentInstance)
		expect(typeof(values.props)).to.equal("table")
		assertDeepEqual(values.props, props)
	end)
end
