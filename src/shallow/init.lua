local ShallowWrapper = require(script.Parent.ShallowWrapper)

local function shallow()
	options = options or {}
	local maxDepth = options.depth or 1
	local internalData = self[internalDataSymbol]

	if config.typeChecks then
		assert(Type.of(self) == Type.VirtualTree, "Expected arg #1 to be a Roact handle")
		assert(internalData.mounted, "Cannot get render output from an unmounted Roact tree")
	end

	return ShallowWrapper.new(internalData.rootNode, maxDepth)
end

return shallow