local Type = require(script.Parent.Type)
local ShallowWrapper = require(script.ShallowWrapper)

local function shallow(rootNode, depth)
	assert(Type.of(rootNode) == Type.VirtualNode, "Expected arg #1 to be a VirtualNode")
	assert(depth == nil or type(depth) == "number", "Expected arg #2 to be a number")

	depth = depth or 1

	return ShallowWrapper.new(rootNode, depth)
end

return shallow