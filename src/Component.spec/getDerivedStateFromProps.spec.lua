return function()
	local assertDeepEqual = require(script.Parent.Parent.assertDeepEqual)
	local createSpy = require(script.Parent.Parent.createSpy)
	local createElement = require(script.Parent.Parent.createElement)
	local createFragment = require(script.Parent.Parent.createFragment)
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

		local node = noopReconciler.mountVirtualNode(
			createElement(WithDerivedState, {
				someProp = 1,
			}),
			hostParent,
			hostKey
		)

		noopReconciler.updateVirtualNode(
			node,
			createElement(WithDerivedState, {
				someProp = 2,
			})
		)

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

		-- getDerivedStateFromProps will be called:
		-- * Once on empty props
		-- * Once during the self:setState in init
		-- * Once more, defensively, on the resulting state AFTER init
		-- * On updating with new state via updateVirtualNode
		expect(getDerivedSpy.callCount).to.equal(4)

		local values = getDerivedSpy:captureValues("props", "state")

		assertDeepEqual(values.props, {})
		assertDeepEqual(values.state, { someState = 2 })
	end)

	it("should be invoked when updating via state in init (which skips reconciliation)", function()
		local getDerivedSpy = createSpy()
		local WithDerivedState = Component:extend("WithDerivedState")

		WithDerivedState.getDerivedStateFromProps = getDerivedSpy.value

		function WithDerivedState:init()
			self:setState({
				stateFromInit = 1,
			})
		end

		function WithDerivedState:render()
			return nil
		end

		local element = createElement(WithDerivedState, {
			someProp = 1,
		})
		local hostParent = nil
		local hostKey = "WithDerivedState"

		noopReconciler.mountVirtualNode(element, hostParent, hostKey)

		-- getDerivedStateFromProps will be called:
		-- * Once on empty props
		-- * Once during the self:setState in init
		-- * Once more, defensively, on the resulting state AFTER init
		expect(getDerivedSpy.callCount).to.equal(3)

		local values = getDerivedSpy:captureValues("props", "state")

		assertDeepEqual(values.props, {
			someProp = 1,
		})
		assertDeepEqual(values.state, {
			stateFromInit = 1,
		})
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

	it("should derive state for all setState updates, even when deferred", function()
		local Child = Component:extend("Child")
		local stateUpdaterSpy = createSpy(function()
			return {}
		end)
		local stateDerivedSpy = createSpy()

		function Child:render()
			return nil
		end

		function Child:didMount()
			self.props.callback()
		end

		local Parent = Component:extend("Parent")

		Parent.getDerivedStateFromProps = stateDerivedSpy.value

		function Parent:render()
			local callback = function()
				self:setState(stateUpdaterSpy.value)
			end

			return createFragment({
				ChildA = createElement(Child, {
					callback = callback,
				}),
				ChildB = createElement(Child, {
					callback = callback,
				}),
			})
		end

		local element = createElement(Parent)
		local hostParent = nil
		local key = "Test"

		noopReconciler.mountVirtualNode(element, hostParent, key)

		expect(stateUpdaterSpy.callCount).to.equal(2)

		-- getDerivedStateFromProps is always called on initial state
		expect(stateDerivedSpy.callCount).to.equal(3)
	end)

	it("should have derived state after assigning to state in init", function()
		local getStateCallback
		local getDerivedSpy = createSpy(function()
			return {
				derived = true,
			}
		end)
		local WithDerivedState = Component:extend("WithDerivedState")

		WithDerivedState.getDerivedStateFromProps = getDerivedSpy.value

		function WithDerivedState:init()
			self.state = {
				init = true,
			}

			getStateCallback = function()
				return self.state
			end
		end

		function WithDerivedState:render()
			return nil
		end

		local hostParent = nil
		local hostKey = "WithDerivedState"
		local element = createElement(WithDerivedState)

		noopReconciler.mountVirtualNode(element, hostParent, hostKey)

		expect(getDerivedSpy.callCount).to.equal(2)

		assertDeepEqual(getStateCallback(), {
			init = true,
			derived = true,
		})
	end)
end
