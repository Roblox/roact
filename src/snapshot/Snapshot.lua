local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Markers = require(script.Parent.Serialize.Markers)
local Serialize = require(script.Parent.Serialize)
local deepEqual = require(script.Parent.Parent.deepEqual)
local ElementKind = require(script.Parent.Parent.ElementKind)

local SnapshotFolderName = "RoactSnapshots"
local SnapshotFolder = ReplicatedStorage:FindFirstChild(SnapshotFolderName)

local Snapshot = {}
local SnapshotMetatable = {
	__index = Snapshot,
	__tostring = function(snapshot)
		return Serialize.snapshotDataToString(snapshot.data)
	end
}

function Snapshot.new(identifier, data)
	local snapshot = {
		_identifier = identifier,
		data = data,
		_existingData = Snapshot._loadExistingData(identifier),
	}

	setmetatable(snapshot, SnapshotMetatable)

	return snapshot
end

function Snapshot:match()
	if self._existingData == nil then
		self:serialize()
		self._existingData = self.data
		return
	end

	local areEqual, innerMessageTemplate = deepEqual(self.data, self._existingData)

	if areEqual then
		return
	end

	local failingSnapshot = Snapshot.new(self._identifier .. ".FAILED", self.data)
	failingSnapshot:serialize()

	local innerMessage = innerMessageTemplate
		:gsub("{1}", "new")
		:gsub("{2}", "existing")

	local message = ("Snapshots do not match.\n%s"):format(innerMessage)

	error(message, 2)
end

function Snapshot:serialize()
	local folder = Snapshot.getSnapshotFolder()

	local snapshotSource = Serialize.snapshotDataToString(self.data)
	local existingData = folder:FindFirstChild(self._identifier)

	if not existingData then
		existingData = Instance.new("StringValue")
		existingData.Name = self._identifier
		existingData.Parent = folder
	end

	existingData.Value = snapshotSource
end

function Snapshot.getSnapshotFolder()
	SnapshotFolder = ReplicatedStorage:FindFirstChild(SnapshotFolderName)

	if not SnapshotFolder then
		SnapshotFolder = Instance.new("Folder")
		SnapshotFolder.Name = SnapshotFolderName
		SnapshotFolder.Parent = ReplicatedStorage
	end

	return SnapshotFolder
end

function Snapshot._loadExistingData(identifier)
	local folder = Snapshot.getSnapshotFolder()

	local existingData = folder:FindFirstChild(identifier)

	if not (existingData and existingData:IsA("ModuleScript")) then
		return nil
	end

	local loadSnapshot = require(existingData)

	return loadSnapshot({
		Roact = require(script.Parent.Parent),
		ElementKind = ElementKind,
		Markers = Markers,
	})
end

return Snapshot