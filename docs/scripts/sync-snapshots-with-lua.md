Do not forget to adjust some of the variables to fit your project.

!!! Warning
	This script assume that `rojo` and `run-in-roblox` commands are available. Make sure that you have installed these two programs before executing this script.

	You will also need to modify the script that boot the tests run to print the new snapshots to the output. It can be done by adding these few lines after tests are run.
	```lua
	--- add the following code after `TestEZ.TestBootstrap:run(...)`
	local RoactSnapshots = ReplicatedStorage:WaitForChild("RoactSnapshots", 1)

	if not RoactSnapshots then
		return nil
	end

	for _, snapshot in pairs(RoactSnapshots:GetChildren()) do
		if snapshot:IsA("StringValue") then
			print(("Snapshot:::<|%s|><|=>%s<=|>"):format(snapshot.Name, snapshot.Value))
		end
	end
	```

---

Using Lua stand alone interpreter, run the following script with the following command.
```
lua path-to-file.lua
```

---

```lua
local lfs = require("lfs")

-- the rojo configuration file used to build a roblox place where tests
-- are going to be run
local ROJO_PROJECT_FILE = "default.project.json"
-- the lua file that is going to be run inside the test place
-- this script needs to print the snapshots to the output
local TEST_FILE = "bin/print-snapshots.lua"

-- the folder that contains the snapshots on the file system
local SNAPSHOTS_FOLDER = "RoactSnapshots"
-- the temporary file that will be created
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
local output = executeCommand(("run-in-roblox %s -s %s -t 60"):format(
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
```