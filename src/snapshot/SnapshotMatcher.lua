local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Markers = require(script.Parent.Serialize.Markers)
local Serialize = require(script.Parent.Serialize)
local deepEqual = require(script.Parent.Parent.deepEqual)
local ElementKind = require(script.Parent.Parent.ElementKind)

local SnapshotFolderName = "RoactSnapshots"
local SnapshotFolder = ReplicatedStorage:FindFirstChild(SnapshotFolderName)

local SnapshotMatcher = {}
local SnapshotMetatable = {
	__index = SnapshotMatcher,
	__tostring = function(snapshot)
		return Serialize.snapshotDataToString(snapshot.data)
	end
}

function SnapshotMatcher.new(identifier, data)
	local snapshot = {
		_identifier = identifier,
		data = data,
		_existingData = SnapshotMatcher._loadExistingData(identifier),
	}

	setmetatable(snapshot, SnapshotMetatable)

	return snapshot
end

function SnapshotMatcher:match()
	if self._existingData == nil then
		self:serialize()
		self._existingData = self.data
		return
	end

	local areEqual, innerMessageTemplate = deepEqual(self.data, self._existingData)

	if areEqual then
		return
	end

	local newSnapshot = SnapshotMatcher.new(self._identifier .. ".NEW", self.data)
	newSnapshot:serialize()

	local innerMessage = innerMessageTemplate
		:gsub("{1}", "new")
		:gsub("{2}", "existing")

	local message = ("Snapshots do not match.\n%s"):format(innerMessage)

	error(message, 2)
end

function SnapshotMatcher:serialize()
	local folder = SnapshotMatcher.getSnapshotFolder()

	local snapshotSource = Serialize.snapshotDataToString(self.data)
	local existingData = folder:FindFirstChild(self._identifier)

	if not (existingData and existingData:IsA('StringValue')) then
		existingData = Instance.new("StringValue")
		existingData.Name = self._identifier
		existingData.Parent = folder
	end

	existingData.Value = snapshotSource
end

function SnapshotMatcher.getSnapshotFolder()
	SnapshotFolder = ReplicatedStorage:FindFirstChild(SnapshotFolderName)

	if not SnapshotFolder then
		SnapshotFolder = Instance.new("Folder")
		SnapshotFolder.Name = SnapshotFolderName
		SnapshotFolder.Parent = ReplicatedStorage
	end

	return SnapshotFolder
end

function SnapshotMatcher._loadExistingData(identifier)
	local folder = SnapshotMatcher.getSnapshotFolder()

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

return SnapshotMatcher