local createFragment = require(script.Parent.createFragment)
local createElement = require(script.Parent.createElement)
local Children = require(script.Parent.PropMarkers.Children)
local PureComponent = require(script.Parent.PureComponent)

local Provider = PureComponent:extend("Provider")

function Provider:render()
	local props = self.props
	local items = props.Contexts

	local children = props[Children]
	local root = createFragment(children)

	for index = #items, 1, -1 do
		local item = items[index]
		local createProvider = item.createProvider
		assert(createProvider and type(createProvider) == "function",
			string.format("provide: Item at %i was not a Context", index))
		root = item:createProvider(root)
	end

	return root
end

local function provide(contexts, children)
	assert(type(contexts) == "table", "Invalid argument #1 to provide, expected table")
	assert(type(children) == "table", "Invalid argument #2 to provide, expected table")

	return createElement(Provider, {
		Contexts = contexts,
	}, children)
end

return provide
