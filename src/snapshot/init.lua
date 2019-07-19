local Serialize = require(script.Serialize)
local Snapshot = require(script.Snapshot)

return function(identifier, shallowWrapper)
	local data = Serialize.wrapperToSnapshotData(shallowWrapper)
	local snapshot = Snapshot.new(identifier, data)

	return snapshot
end
