return function()
	local Snapshot = require(script.Parent.Snapshot)

	local ElementKind = require(script.Parent.Parent.ElementKind)
	local createSpy = require(script.Parent.Parent.createSpy)

	local snapshotFolder = Instance.new("Folder")
	local originalGetSnapshotFolder = Snapshot.getSnapshotFolder

	local function mockGetSnapshotFolder()
		return snapshotFolder
	end

	local originalLoadExistingData = Snapshot._loadExistingData
	local loadExistingDataSpy = nil

	describe("match", function()
		local snapshotMap = {}

		local function beforeTest()
			snapshotMap = {}

			loadExistingDataSpy = createSpy(function(identifier)
				return snapshotMap[identifier]
			end)
			Snapshot._loadExistingData = loadExistingDataSpy.value
		end

		local function cleanTest()
			loadExistingDataSpy = nil
			Snapshot._loadExistingData = originalLoadExistingData
		end

		it("should serialize the snapshot if no data is found", function()
			beforeTest()

			local data = {}

			local serializeSpy = createSpy()

			local snapshot = Snapshot.new("foo", data)
			snapshot.serialize = serializeSpy.value

			snapshot:match()

			cleanTest()

			serializeSpy:assertCalledWith(snapshot)
		end)

		it("should not serialize if the snapshot already exist", function()
			beforeTest()

			local data = {}
			local identifier = "foo"
			snapshotMap[identifier] = data

			local serializeSpy = createSpy()

			local snapshot = Snapshot.new(identifier, data)
			snapshot.serialize = serializeSpy.value

			snapshot:match()

			cleanTest()

			expect(serializeSpy.callCount).to.equal(0)
		end)

		it("should throw an error if the previous snapshot does not match", function()
			beforeTest()

			local data = {}
			local identifier = "foo"
			snapshotMap[identifier] = {
				Key = "Value"
			}

			local serializeSpy = createSpy()

			local snapshot = Snapshot.new(identifier, data)
			snapshot.serialize = serializeSpy.value

			local function shouldThrow()
				snapshot:match()
			end

			cleanTest()

			expect(shouldThrow).to.throw()
		end)
	end)

	describe("serialize", function()
		it("should create a StringValue if it does not exist", function()
			Snapshot.getSnapshotFolder = mockGetSnapshotFolder

			local identifier = "foo"

			local snapshot = Snapshot.new(identifier, {
				type = {
					kind = ElementKind.Function,
				},
				hostKey = "HostKey",
				props = {},
				children = {},
			})

			snapshot:serialize()
			local stringValue = snapshotFolder:FindFirstChild(identifier)

			Snapshot.getSnapshotFolder = originalGetSnapshotFolder

			expect(stringValue).to.be.ok()
			expect(stringValue.Value:len() > 0).to.equal(true)

			stringValue:Destroy()
		end)
	end)

	describe("_loadExistingData", function()
		it("should return nil if data is not found", function()
			Snapshot.getSnapshotFolder = mockGetSnapshotFolder

			local result = Snapshot._loadExistingData("foo")

			Snapshot.getSnapshotFolder = originalGetSnapshotFolder

			expect(result).never.to.be.ok()
		end)
	end)

	describe("getSnapshotFolder", function()
		it("should create a folder in the ReplicatedStorage if it is not found", function()
			local folder = Snapshot.getSnapshotFolder()

			expect(folder).to.be.ok()
			expect(folder.Parent).to.equal(game:GetService("ReplicatedStorage"))
		end)
	end)
end