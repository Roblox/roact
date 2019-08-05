local Serializer = require(script.Serializer)
local Snapshot = require(script.Snapshot)

return {
	wrapperToSnapshot = function(wrapper)
		return Snapshot.wrapper(wrapper)
	end,
	snapshotToString = function(snapshot)
		return Serializer.firstSnapshotData(snapshot)
	end,
}
