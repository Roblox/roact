local Serializer = require(script.Serializer)
local SnapshotData = require(script.SnapshotData)

return {
	wrapperToSnapshotData = function(wrapper)
		return SnapshotData.wrapper(wrapper)
	end,
	snapshotDataToString = function(data)
		return Serializer.firstSnapshotData(data)
	end,
}
