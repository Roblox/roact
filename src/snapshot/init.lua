local Serialize = require(script.Serialize)
local SnapshotMatcher = require(script.SnapshotMatcher)

local characterClass = "%w_%-%."
local identifierPattern = "^[" .. characterClass .. "]+$"
local invalidPattern = "[^" .. characterClass .. "]"

return function(identifier, shallowWrapper)
	if not identifier:match(identifierPattern) then
		error(("Snapshot identifier has invalid character: '%s'"):format(identifier:match(invalidPattern)))
	end

	local data = Serialize.wrapperToSnapshotData(shallowWrapper)
	local matcher = SnapshotMatcher.new(identifier, data)

	return matcher
end
