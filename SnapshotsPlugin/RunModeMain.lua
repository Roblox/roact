local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Settings = require(script.Parent.Settings)

local function PluginRunMode(plugin)
	plugin.Unloading:Connect(function()
		local snapshotsFolder = ReplicatedStorage:FindFirstChild(Settings.SnapshotFolderName)

		local newSnapshots = {}

		if not snapshotsFolder then
			return
		end

		for _, snapshot in pairs(snapshotsFolder:GetChildren()) do
			if snapshot:IsA("StringValue") then
				newSnapshots[snapshot.Name] = snapshot.Value
			end
		end

		plugin:SetSetting(Settings.PluginSettingName, newSnapshots)
	end)
end

return PluginRunMode