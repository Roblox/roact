local Symbol = require(script.Parent.Symbol)
local Binding = require(script.Parent.Binding)
local oneChild = require(script.Parent.oneChild)
local Children = require(script.Parent.PropMarkers.Children)
local PureComponent = require(script.Parent.PureComponent)

local function createProvider(context)
	local Provider = PureComponent:extend("Provider")

	function Provider:init(props)
		self.binding, self.updateValue = Binding.create(props.value)

		local key = context.key
		self._context[key] = self.binding
	end

	function Provider:didUpdate()
		self.updateValue(self.props.value)
	end

	function Provider:render()
		return oneChild(self.props[Children])
	end

	return Provider
end

local function createConsumer(context)
	local Consumer = PureComponent:extend("Consumer")

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

	function Consumer:render()
		assert(type(self.props.render) == "function", "Consumer expects a `render` function")
		return self.props.render(self.state.value)
	end

	function Consumer:willUnmount()
		if self.disconnect then
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
	return tostring(self.defaultValue)
end

local function createContext(defaultValue)
	local context = Context.new(defaultValue)
	return {
		Provider = createProvider(context),
		Consumer = createConsumer(context),
	}
end

return createContext
