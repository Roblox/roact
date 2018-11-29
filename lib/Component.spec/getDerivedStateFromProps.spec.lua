return function()
	local assertDeepEqual = require(script.Parent.Parent.assertDeepEqual)
	local createSpy = require(script.Parent.Parent.createSpy)
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be invoked on initial mount", function()
		local getDerivedSpy = createSpy()
		local WithDerivedState = Component:extend("WithDerivedState")

		WithDerivedState.getDerivedStateFromProps = getDerivedSpy.value

		function WithDerivedState:render()
			return nil
		end

		local element = createElement(WithDerivedState, {
			someProp = 1,
		})
		local hostParent = nil
		local hostKey = "WithDerivedState"

		noopReconciler.mountVirtualNode(element, hostParent, hostKey)

		expect(getDerivedSpy.callCount).to.equal(1)

		local values = getDerivedSpy:captureValues("props", "state")

		assertDeepEqual(values.props, { someProp = 1 })
		assertDeepEqual(values.state, {})
	end)

	it("should be invoked when updated via props", function()
		local getDerivedSpy = createSpy()
		local WithDerivedState = Component:extend("WithDerivedState")

		WithDerivedState.getDerivedStateFromProps = getDerivedSpy.value

		function WithDerivedState:render()
			return nil
		end

		local hostParent = nil
		local hostKey = "WithDerivedState"

		local node = noopReconciler.mountVirtualNode(createElement(WithDerivedState, {
			someProp = 1,
		}), hostParent, hostKey)

		noopReconciler.updateVirtualNode(node, createElement(WithDerivedState, {
			someProp = 2,
		}))

		expect(getDerivedSpy.callCount).to.equal(2)

		local values = getDerivedSpy:captureValues("props", "state")

		assertDeepEqual(values.props, { someProp = 2 })
		assertDeepEqual(values.state, {})
	end)

	it("should be invoked when updated via state", function()
		local getDerivedSpy = createSpy()
		local WithDerivedState = Component:extend("WithDerivedState")

		WithDerivedState.getDerivedStateFromProps = getDerivedSpy.value

		function WithDerivedState:init()
			self:setState({
				someState = 1,
			})
		end

		function WithDerivedState:render()
			return nil
		end

		local element = createElement(WithDerivedState)
		local hostParent = nil
		local hostKey = "WithDerivedState"

		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey)

		noopReconciler.updateVirtualNode(node, element, {
			someState = 2,
		})

		expect(getDerivedSpy.callCount).to.equal(2)

		local values = getDerivedSpy:captureValues("props", "state")

		assertDeepEqual(values.props, {})
		assertDeepEqual(values.state, { someState = 2 })
	end)

	it("should receive defaultProps", function()
		local getDerivedSpy = createSpy()
		local WithDerivedState = Component:extend("WithDerivedState")

		WithDerivedState.defaultProps = {
			someDefaultProp = "foo",
		}

		WithDerivedState.getDerivedStateFromProps = getDerivedSpy.value

		function WithDerivedState:render()
			return nil
		end

		local element = createElement(WithDerivedState, {
			someProp = 1,
		})
		local hostParent = nil
		local hostKey = "WithDerivedState"

		local node = noopReconciler.mountVirtualNode(element, hostParent, hostKey)

		expect(getDerivedSpy.callCount).to.equal(1)

		local values = getDerivedSpy:captureValues("props", "state")

		assertDeepEqual(values.props, {
			someDefaultProp = "foo",
			someProp = 1,
		})

		-- Update via props, confirm that defaultProp is still present
		element = createElement(WithDerivedState, {
			someProp = 2,
		})

		noopReconciler.updateVirtualNode(node, element)

		expect(getDerivedSpy.callCount).to.equal(2)

		values = getDerivedSpy:captureValues("props", "state")

		assertDeepEqual(values.props, {
			someDefaultProp = "foo",
			someProp = 2,
		})
	end)
end