return function()
	local assertDeepEqual = require(script.Parent.Parent.assertDeepEqual)
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local None = require(script.Parent.Parent.None)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should fill in when mounting before init", function()
		local defaultProps = {
			a = 3,
			b = 2,
		}

		local Foo = Component:extend("Foo")

		Foo.defaultProps = defaultProps

		local capturedProps
		function Foo:init()
			capturedProps = self.props
		end

		function Foo:render() end

		local initialProps = {
			b = 4,
			c = 6,
		}

		local element = createElement(Foo, initialProps)
		local hostParent = nil
		local key = "Some Foo"

		noopReconciler.mountVirtualNode(element, hostParent, key)

		local expectedProps = {
			a = defaultProps.a,
			b = initialProps.b,
			c = initialProps.c,
		}

		assertDeepEqual(capturedProps, expectedProps)
	end)

	it("should fill in when updating via props", function()
		local defaultProps = {
			a = 3,
			b = 2,
		}

		local Foo = Component:extend("Foo")

		Foo.defaultProps = defaultProps

		local capturedProps
		function Foo:render()
			capturedProps = self.props
		end

		local initialProps = {
			b = 4,
			c = 6,
		}

		local element = createElement(Foo, initialProps)
		local hostParent = nil
		local key = "Some Foo"

		local node = noopReconciler.mountVirtualNode(element, hostParent, key)

		local updatedProps = {
			c = 5,
		}
		local updatedElement = createElement(Foo, updatedProps)

		noopReconciler.updateVirtualNode(node, updatedElement)

		local expectedProps = {
			a = defaultProps.a,
			b = defaultProps.b,
			c = updatedProps.c,
		}

		assertDeepEqual(capturedProps, expectedProps)
	end)

	it("should respect None to override a default prop with nil", function()
		local defaultProps = {
			a = 3,
			b = 2,
		}

		local Foo = Component:extend("Foo")

		Foo.defaultProps = defaultProps

		local capturedProps
		function Foo:render()
			capturedProps = self.props
		end

		local initialProps = {
			b = None,
			c = 4,
		}

		local element = createElement(Foo, initialProps)
		local hostParent = nil
		local key = "Some Foo"

		noopReconciler.mountVirtualNode(element, hostParent, key)

		local expectedProps = {
			a = defaultProps.a,
			b = nil,
			c = initialProps.c,
		}

		assertDeepEqual(capturedProps, expectedProps)
	end)
end
