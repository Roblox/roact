return function()
	local createElement = require(script.Parent.createElement)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local createReconciler = require(script.Parent.createReconciler)
	local VirtualTree = require(script.Parent.VirtualTree)

	local PureComponent = require(script.Parent.PureComponent)

	local noopReconciler = createReconciler(NoopRenderer)

	local function mountWithNoop(element, hostParent, hostKey)
		return VirtualTree.mount(element, {
			hostParent = hostParent,
			hostKey = hostKey,
			reconciler = noopReconciler
		})
	end

	it("should be extendable", function()
		local MyComponent = PureComponent:extend("MyComponent")

		expect(MyComponent).to.be.ok()
	end)

	it("should skip updates for shallow-equal props", function()
		local updateCount = 0
		local setValue

		local PureChild = PureComponent:extend("PureChild")

		function PureChild:willUpdate()
			updateCount = updateCount + 1
		end

		function PureChild:render()
			return nil
		end

		local PureContainer = PureComponent:extend("PureContainer")

		function PureContainer:init()
			self.state = {
				value = 0,
			}
		end

		function PureContainer:didMount()
			setValue = function(value)
				self:setState({
					value = value,
				})
			end
		end

		function PureContainer:render()
			return createElement(PureChild, {
				value = self.state.value,
			})
		end

		local element = createElement(PureContainer)
		local tree = mountWithNoop(element, nil, "PureComponent Tree")

		expect(updateCount).to.equal(0)

		setValue(1)

		expect(updateCount).to.equal(1)

		setValue(1)

		expect(updateCount).to.equal(1)

		setValue(2)

		expect(updateCount).to.equal(2)

		setValue(1)

		expect(updateCount).to.equal(3)

		VirtualTree.unmount(tree)
	end)
end