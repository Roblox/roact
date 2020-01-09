local Symbol = require(script.Parent.Symbol)
local createSignal = require(script.Parent.createSignal)
local createElement = require(script.Parent.createElement)
local PureComponent = require(script.Parent.PureComponent)
local oneChild = require(script.Parent.oneChild)
local Children = require(script.Parent.PropMarkers.Children)

local Provider = PureComponent:extend("Provider")

function Provider:init(props)
	local context = props.Context
	local key = context.key
	self._context[key] = context
end

function Provider:render()
	return oneChild(self.props[Children])
end

local Context = {}
Context.__index = Context

function Context.new(defaultValue)
	local self = {
		updateSignal = createSignal(),
		value = defaultValue,
		key = Symbol.named("Context"),
	}
	setmetatable(self, Context)
	return self
end

function Context:__tostring()
	if self.displayName then
		return self.displayName
	else
		return "Context"
	end
end

function Context:getValue()
	return self.value
end

function Context:update(value)
	self.value = value
	self.updateSignal:fire()
end

function Context:createProvider(root)
	return createElement(Provider, {
		Context = self,
	}, {root})
end

local function createContext(defaultValue)
	return Context.new(defaultValue)
end

return createContext
