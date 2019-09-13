return function()
	local RoactRoot = script.Parent.Parent.Parent

	local SnapshotMatcher = require(script.Parent.SnapshotMatcher)

	local ElementKind = require(RoactRoot.ElementKind)
	local createSpy = require(RoactRoot.createSpy)

	local snapshotFolder = Instance.new("Folder")
	local originalGetSnapshotFolder = SnapshotMatcher.getSnapshotFolder

	local function mockGetSnapshotFolder()
		return snapshotFolder
	end

	local function getSnapshotMock()
		return {
			type = {
				kind = ElementKind.Function,
			},
			hostKey = "HostKey",
			props = {},
			children = {},
		}
	end

	local originalLoadExistingData = SnapshotMatcher._loadExistingData
	local loadExistingDataSpy = nil

	describe("match", function()
		local snapshotMap = {}

		local function beforeTest()
			snapshotMap = {}

			loadExistingDataSpy = createSpy(function(identifier)
				return snapshotMap[identifier]
			end)
			SnapshotMatcher._loadExistingData = loadExistingDataSpy.value
			SnapshotMatcher.getSnapshotFolder = mockGetSnapshotFolder
		end

		local function cleanTest()
			loadExistingDataSpy = nil
			SnapshotMatcher._loadExistingData = originalLoadExistingData
			SnapshotMatcher.getSnapshotFolder = originalGetSnapshotFolder
			snapshotFolder:ClearAllChildren()
		end

		it("should throw if no snapshot is found", function()
			beforeTest()

			local snapshot = getSnapshotMock()

			local matcher = SnapshotMatcher.new("foo", snapshot)

			local function shouldThrow()
				matcher:match()
			end

			expect(shouldThrow).to.throw()

			expect(snapshotFolder:FindFirstChild("foo.NEW")).to.be.ok()

			cleanTest()
		end)

		it("should not serialize if the snapshot already exist", function()
			beforeTest()

			local snapshot = getSnapshotMock()
			local identifier = "foo"
			snapshotMap[identifier] = snapshot

			local serializeSpy = createSpy()

			local matcher = SnapshotMatcher.new(identifier, snapshot)
			matcher.serialize = serializeSpy.value

			matcher:match()

			cleanTest()

			expect(serializeSpy.callCount).to.equal(0)
		end)

		it("should throw an error if the previous snapshot does not match", function()
			beforeTest()

			local snapshot = getSnapshotMock()
			local identifier = "foo"
			snapshotMap[identifier] = {
				Key = "Value"
			}

			local serializeSpy = createSpy()

			local matcher = SnapshotMatcher.new(identifier, snapshot)
			matcher.serialize = serializeSpy.value

			local function shouldThrow()
				matcher:match()
			end

			expect(shouldThrow).to.throw()

			cleanTest()
		end)
	end)

	describe("serialize", function()
		it("should create a StringValue if it does not exist", function()
			SnapshotMatcher.getSnapshotFolder = mockGetSnapshotFolder

			local identifier = "foo"

			local matcher = SnapshotMatcher.new(identifier, getSnapshotMock())

			matcher:serialize()
			local stringValue = snapshotFolder:FindFirstChild(identifier)

			SnapshotMatcher.getSnapshotFolder = originalGetSnapshotFolder

			expect(stringValue).to.be.ok()
			expect(stringValue.Value:len() > 0).to.equal(true)

			stringValue:Destroy()
		end)
	end)

	describe("_loadExistingData", function()
		it("should return nil if data is not found", function()
			SnapshotMatcher.getSnapshotFolder = mockGetSnapshotFolder

			local result = SnapshotMatcher._loadExistingData("foo")

			SnapshotMatcher.getSnapshotFolder = originalGetSnapshotFolder

			expect(result).never.to.be.ok()
		end)
	end)

	describe("getSnapshotFolder", function()
		it("should create a folder in the ReplicatedStorage if it is not found", function()
			local folder = SnapshotMatcher.getSnapshotFolder()

			expect(folder).to.be.ok()
			expect(folder.Parent).to.equal(game:GetService("ReplicatedStorage"))
		end)
	end)
end