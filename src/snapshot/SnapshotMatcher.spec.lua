return function()
	local SnapshotMatcher = require(script.Parent.SnapshotMatcher)

	local ElementKind = require(script.Parent.Parent.ElementKind)
	local createSpy = require(script.Parent.Parent.createSpy)

	local snapshotFolder = Instance.new("Folder")
	local originalGetSnapshotFolder = SnapshotMatcher.getSnapshotFolder

	local function mockGetSnapshotFolder()
		return snapshotFolder
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
		end

		local function cleanTest()
			loadExistingDataSpy = nil
			SnapshotMatcher._loadExistingData = originalLoadExistingData
		end

		it("should serialize the snapshot if no data is found", function()
			beforeTest()

			local snapshot = {}
			local serializeSpy = createSpy()

			local matcher = SnapshotMatcher.new("foo", snapshot)
			matcher.serialize = serializeSpy.value

			matcher:match()

			cleanTest()

			serializeSpy:assertCalledWith(matcher)
		end)

		it("should not serialize if the snapshot already exist", function()
			beforeTest()

			local snapshot = {}
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

			local snapshot = {}
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

			cleanTest()

			expect(shouldThrow).to.throw()
		end)
	end)

	describe("serialize", function()
		it("should create a StringValue if it does not exist", function()
			SnapshotMatcher.getSnapshotFolder = mockGetSnapshotFolder

			local identifier = "foo"

			local matcher = SnapshotMatcher.new(identifier, {
				type = {
					kind = ElementKind.Function,
				},
				hostKey = "HostKey",
				props = {},
				children = {},
			})

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