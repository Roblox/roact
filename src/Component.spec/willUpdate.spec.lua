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

		local willUpdateSpy = createSpy()

		MyComponent.willUpdate = willUpdateSpy.value

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

		expect(willUpdateSpy.callCount).to.equal(1)

		local values = willUpdateSpy:captureValues("self", "newProps", "newState")

		expect(Type.of(values.self)).to.equal(Type.StatefulComponentInstance)
		assertDeepEqual(values.newProps, newProps)
		assertDeepEqual(values.newState, {})
	end)

	it("it should be invoked when updated via setState", function()
		local MyComponent = Component:extend("MyComponent")
		local setComponentState

		local willUpdateSpy = createSpy()

		MyComponent.willUpdate = willUpdateSpy.value

		function MyComponent:init()
			setComponentState = function(state)
				self:setState(state)
			end

			self:setState({
				foo = 1,
			})
		end

		function MyComponent:render()
			return nil
		end

		local initialElement = createElement(MyComponent)
		local hostParent = nil
		local key = "Test"

		noopReconciler.mountVirtualNode(initialElement, hostParent, key)

		expect(willUpdateSpy.callCount).to.equal(0)

		setComponentState({
			foo = 2,
		})

		expect(willUpdateSpy.callCount).to.equal(1)

		local values = willUpdateSpy:captureValues("self", "newProps", "newState")

		expect(Type.of(values.self)).to.equal(Type.StatefulComponentInstance)
		assertDeepEqual(values.newProps, {})
		assertDeepEqual(values.newState, {
			foo = 2,
		})
	end)
end
