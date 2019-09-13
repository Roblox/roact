local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(script.Parent.Settings)

local function SyncSnapshots(newSnapshots)
	local snapshotsFolder = ReplicatedStorage:FindFirstChild(Settings.SnapshotFolderName)

	if not snapshotsFolder then
		snapshotsFolder = Instance.new("Folder")
		snapshotsFolder.Name = Settings.SnapshotFolderName
		snapshotsFolder.Parent = ReplicatedStorage
	end

	for name, value in pairs(newSnapshots) do
		local snapshot = Instance.new("ModuleScript")
		snapshot.Name = name
		snapshot.Source = value
		snapshot.Parent = snapshotsFolder
	end
end

local function PluginEditMode(plugin)
	local isPluginDeactivated = false

	plugin.Deactivation:Connect(function()
		isPluginDeactivated = true
	end)

	while not isPluginDeactivated do
		local newSnapshots = plugin:GetSetting(Settings.PluginSettingName)

		if newSnapshots then
			SyncSnapshots(newSnapshots)
			plugin:SetSetting(Settings.PluginSettingName, false)
		end

		wait(Settings.SyncDelay)
	end
end

return PluginEditMode