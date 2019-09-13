local lfs = require("lfs")

local ROJO_PROJECT_FILE = "place.project.json"
local TEST_FILE = "bin/run-tests-snapshots.lua"

local SNAPSHOTS_FOLDER = "RoactSnapshots"
local TEST_PLACE_FILE_NAME = "temp-snapshot-place.rbxlx"

local function writeSnapshotFile(name, content)
	lfs.mkdir(SNAPSHOTS_FOLDER)

	local fileName = name .. ".lua"
	local filePath = ("%s/%s"):format(SNAPSHOTS_FOLDER, fileName)

	print("Writing", filePath)

	local file = io.open(filePath, "w")
	file:write(content)
	file:close()
end

local function executeCommand(command)
	print(command)
	local handle = io.popen(command)
	local line = handle:read("*l")
	local output = {line}

	while line do
		line = handle:read("*l")
		table.insert(output, line)
	end

	handle:close()

	return table.concat(output, "\n")
end

print("Building test place")
executeCommand(("rojo build %s -o %s"):format(
	ROJO_PROJECT_FILE,
	TEST_PLACE_FILE_NAME
))

print("Running run-in-roblox")
local output = executeCommand(("run-in-roblox %s -s %s -t 100"):format(
	TEST_PLACE_FILE_NAME,
	TEST_FILE
))

print("Clean test place")
os.remove(TEST_PLACE_FILE_NAME)

print("Processing output...")

local filteredOutput = output:gsub("\nSnapshot:::<|[%w_%-%.]+|><|=>.-<=|>", "")

print(filteredOutput, "\n")

for snapshotPattern in output:gmatch("Snapshot:::<|[%w_%-%.]+|><|=>.-<=|>") do
	local name = snapshotPattern:match("Snapshot:::<|([%w_%-%.]+)|>")
	local content = snapshotPattern:match("<|=>(.-)<=|>")

	writeSnapshotFile(name, content)
end