local function IndexError(_, key)
	local message = ("%q (%s) is not a valid member of Settings"):format(
		tostring(key),
		typeof(key)
	)

	error(message, 2)
end

return setmetatable({
	SnapshotFolderName = "RoactSnapshots",
	PluginSettingName = "NewRoactSnapshots",
	SyncDelay = 1,
}, {
	__index = IndexError,
	__newindex = IndexError,
})