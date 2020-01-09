local PureComponent = require(script.Parent.PureComponent)
local createElement = require(script.Parent.createElement)
local assign = require(script.Parent.assign)

local function consume(contextMap)
	assert(type(contextMap) == "table", "Invalid argument to consume, expected table")

	return function(component)
		assert(component, "consume: Expected a Component to wrap.")
		local componentName = ("Consumer(%s)"):format(tostring(component))
		local Consumer = PureComponent:extend(componentName)

		function Consumer:update(target, item)
			self:setState({
				propsForChild = assign({}, self.state.propsForChild, self.props, {
					[target] = item:getValue(),
				}),
			})
		end

		function Consumer.getDerivedStateFromProps(nextProps, lastState)
			return {
				propsForChild = assign({}, lastState.propsForChild, nextProps),
			}
		end

		function Consumer:init(props)
			self.disconnects = {}
			self.state = {
				propsForChild = props or {},
			}

			for target, contextItem in pairs(contextMap) do
				local key = contextItem.key
				local item = self._context[key]
				assert(item ~= nil, string.format("consume: The Context at %s was not provided.", target))
				assert(item.getValue ~= nil, string.format("consume: The item at %s was not a Context.", target))
				self:update(target, item)

				-- Update if the Context updated
				if item.updateSignal then
					self.disconnects[target] = item.updateSignal:subscribe(function()
						self:update(target, item)
					end)
				end
			end
		end

		function Consumer:render()
			return createElement(component, self.state.propsForChild)
		end

		function Consumer:willUnmount()
			for _, disconnect in pairs(self.disconnects) do
				disconnect()
			end
		end

		return Consumer
	end
end

return consume
