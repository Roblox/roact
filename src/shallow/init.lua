local Type = require(script.Parent.Type)
local ShallowWrapper = require(script.ShallowWrapper)

local optionsTypes = {
	depth = "number",
}

local function validateOptions(options)
	if options == nil then
		return true
	end

	for key, value in pairs(options) do
		local expectType = optionsTypes[key]

		if expectType == nil then
			return false, ("unexpected option field %q (with value of %s)"):format(
				tostring(key),
				tostring(value)
			)
		elseif typeof(value) ~= expectType then
			return false, ("unexpected option type for %q (expected %s but got %s)"):format(
				tostring(key),
				expectType,
				typeof(value)
			)
		end
	end

	return true
end

local function shallow(rootNode, options)
	assert(Type.of(rootNode) == Type.VirtualNode, "Expected arg #1 to be a VirtualNode")
	assert(validateOptions(options))

	options = options or {}
	local maxDepth = options.depth or 1

	return ShallowWrapper.new(rootNode, maxDepth)
end

return shallow