local ShallowWrapper = require(script.Parent.shallow.ShallowWrapper)
local Type = require(script.Parent.Type)

local config = require(script.Parent.GlobalConfig).get()

local VirtualTree = {}

function VirtualTree.new(rootNode, internalDataSymbol, mounted)
	local tree = {
		[Type] = Type.VirtualTree,
		[internalDataSymbol] = {
			rootNode = rootNode,
			mounted = mounted,
		}
	}

	function tree:getTestRenderOutput(options)
		options = options or {}
		local maxDepth = options.depth or 1
		local internalData = self[internalDataSymbol]

		if config.typeChecks then
			assert(Type.of(self) == Type.VirtualTree, "Expected arg #1 to be a Roact handle")
			assert(internalData.mounted, "Cannot get render output from an unmounted Roact tree")
		end

		return ShallowWrapper.new(internalData.rootNode, maxDepth)
	end

	return tree
end

return VirtualTree