return function()
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local createSpy = require(script.Parent.Parent.createSpy)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local Type = require(script.Parent.Parent.Type)
	local deepEqual = require(script.Parent.Parent.deepEqual)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be invoked when updated via updateNode", function()
		local MyComponent = Component:extend("MyComponent")

		local didUpdateSpy = createSpy(function(props)
			return nil
		end)

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

		local node = noopReconciler.mountNode(initialElement, hostParent, key)

		local newProps = {
			a = 6,
			b = 2,
		}
		local newElement = createElement(MyComponent, newProps)
		noopReconciler.updateNode(node, newElement)

		expect(didUpdateSpy.callCount).to.equal(1)

		local values = didUpdateSpy:captureValues("self", "oldProps", "oldState")

		expect(Type.of(values.self)).to.equal(Type.StatefulComponentInstance)
		assert(deepEqual(values.oldProps, initialProps), "Expected newProps to equal passed in props")
		assert(deepEqual(values.oldState, {}), "Expected newState to be empty")
	end)

	-- TODO: it should be invoked when updated via setState
end