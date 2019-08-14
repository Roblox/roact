local Type = require(script.Parent.Type)
local ShallowWrapper = require(script.ShallowWrapper)
local validateShallowOptions = require(script.validateShallowOptions)

local function shallow(rootNode, options)
	assert(Type.of(rootNode) == Type.VirtualNode, "Expected arg #1 to be a VirtualNode")
	assert(validateShallowOptions(options))

	options = options or {}
	local maxDepth = options.depth or 1

	return ShallowWrapper.new(rootNode, maxDepth)
end

return shallow