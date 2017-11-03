return function()
	local Core = require(script.Parent.Core)
	local Reconciler = require(script.Parent.Reconciler)
	local PureComponent = require(script.Parent.PureComponent)

	it("should be extendable", function()
		local MyComponent = PureComponent:extend("MyComponent")

		expect(MyComponent).to.be.ok()
	end)

	it("should skip updates for shallow-equal props", function()
		local updateCount = 0
		local setValue

		local PureChild = PureComponent:extend("PureChild")

		function PureChild:willUpdate(newProps, newState)
			updateCount = updateCount + 1
		end

		function PureChild:render()
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
			return Core.createElement(PureChild, {
				value = self.state.value,
			})
		end

		local element = Core.createElement(PureContainer)
		local instance = Reconciler.reify(element)

		expect(updateCount).to.equal(0)

		setValue(1)

		expect(updateCount).to.equal(1)

		setValue(1)

		expect(updateCount).to.equal(1)

		setValue(2)

		expect(updateCount).to.equal(2)

		setValue(1)

		expect(updateCount).to.equal(3)

		Reconciler.teardown(instance)
	end)
end