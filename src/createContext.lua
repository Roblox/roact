local Symbol = require(script.Parent.Symbol)
local Binding = require(script.Parent.Binding)
local createFragment = require(script.Parent.createFragment)
local Children = require(script.Parent.PropMarkers.Children)
local Component = require(script.Parent.Component)

local function createProvider(context)
	local Provider = Component:extend("Provider")

	function Provider:init(props)
		self.binding, self.updateValue = Binding.create(props.value)

		local key = context.key
		self._context[key] = self.binding
	end

	function Provider:didUpdate(prevProps)
		if prevProps.value ~= self.props.value then
			self.updateValue(self.props.value)
		end
	end

	function Provider:render()
		return createFragment(self.props[Children])
	end

	return Provider
end

local function createConsumer(context)
	local Consumer = Component:extend("Consumer")

	function Consumer:init(props)
		local key = context.key
		local binding = self._context[key]

		if binding ~= nil then
			self.state = {
				value = binding:getValue(),
			}

			-- Update if the Context updated
			self.disconnect = Binding.subscribe(binding, function()
				self:setState({
					value = binding:getValue(),
				})
			end)
		else
			-- Fall back to the default value if no Provider exists
			self.state = {
				value = context.defaultValue,
			}
		end
	end

	function Consumer.validateProps(props)
		if type(props.render) ~= "function" then
			return false, "Consumer expects a `render` function"
		else
			return true
		end
	end

	function Consumer:render()
		return self.props.render(self.state.value)
	end

	function Consumer:willUnmount()
		if self.disconnect ~= nil then
			self.disconnect()
		end
	end

	return Consumer
end

local Context = {}
Context.__index = Context

function Context.new(defaultValue)
	local self = {
		defaultValue = defaultValue,
		key = Symbol.named("ContextKey"),
	}
	setmetatable(self, Context)
	return self
end

function Context:__tostring()
	return "RoactContext"
end

local function createContext(defaultValue)
	local context = Context.new(defaultValue)
	return {
		Provider = createProvider(context),
		Consumer = createConsumer(context),
	}
end

return createContext
