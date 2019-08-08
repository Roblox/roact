local Serialize = require(script.Serialize)
local SnapshotMatcher = require(script.SnapshotMatcher)

local characterClass = "%w_%-%."
local identifierPattern = "^[" .. characterClass .. "]+$"
local invalidPattern = "[^" .. characterClass .. "]"

local function createMatcher(identifier, shallowWrapper)
	if not identifier:match(identifierPattern) then
		error(("Snapshot identifier has invalid character: '%s'"):format(identifier:match(invalidPattern)))
	end

	local snapshot = Serialize.wrapperToSnapshot(shallowWrapper)
	local matcher = SnapshotMatcher.new(identifier, snapshot)

	return matcher
end

local function toString(shallowWrapper)
	local snapshot = Serialize.wrapperToSnapshot(shallowWrapper)

	return Serialize.snapshotToString(snapshot)
end

return {
	createMatcher = createMatcher,
	toString = toString,
}