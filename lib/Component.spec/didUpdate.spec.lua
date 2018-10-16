return function()
	local assertDeepEqual = require(script.Parent.Parent.assertDeepEqual)
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local createSpy = require(script.Parent.Parent.createSpy)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local Type = require(script.Parent.Parent.Type)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be invoked when updated via updateVirtualNode", function()
		local MyComponent = Component:extend("MyComponent")

		local didUpdateSpy = createSpy()

		MyComponent.didUpdate = didUpdateSpy.value

		function MyComponent:render()
			return nil
		end

		local initialProps = {
			a = 5,
		}
		local initialElement = createElement(MyComponent, initialProps)
		local hostParent = nil
		local key = "Test"

		local node = noopReconciler.mountVirtualNode(initialElement, hostParent, key)

		local newProps = {
			a = 6,
			b = 2,
		}
		local newElement = createElement(MyComponent, newProps)
		noopReconciler.updateVirtualNode(node, newElement)

		expect(didUpdateSpy.callCount).to.equal(1)

		local values = didUpdateSpy:captureValues("self", "oldProps", "oldState")

		expect(Type.of(values.self)).to.equal(Type.StatefulComponentInstance)
		assertDeepEqual(values.oldProps, initialProps)
		assertDeepEqual(values.oldState, {})
	end)

	-- TODO: it should be invoked when updated via setState
end