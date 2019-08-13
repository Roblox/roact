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

Using a python interpreter (compatible with 2 or 3), put the following script in a file and run it.
```
python path-to-file.py
```

```python
import os
import re
import subprocess

# the rojo configuration file used to build a roblox place where tests
# are going to be run
ROJO_PROJECT_FILE = 'place.project.json'
# the lua file that is going to be run inside the test place
# this script needs to print the snapshots to the output
TEST_FILE = 'bin/print-snapshots.lua'

# the folder that contains the snapshots on the file system
SNAPSHOTS_FOLDER = 'RoactSnapshots'
# the temporary file that will be created
TEST_PLACE_FILE_NAME = 'temp-snapshot-place.rbxlx'

PATTERN_STR = 'Snapshot:::<\|(?P<name>[\w\.\-]+)\|><\|=>(?P<content>.+?)<=\|>\n'

pattern = re.compile(PATTERN_STR, re.MULTILINE | re.DOTALL)


def write_snapshot_file(name, content):
    if not os.path.exists(SNAPSHOTS_FOLDER):
        os.mkdir(SNAPSHOTS_FOLDER)

    file_name = name + '.lua'
    file_path = os.path.join(SNAPSHOTS_FOLDER, file_name)

    print('Writing ' + file_path)

    with open(file_path, 'w') as snapshot_file:
        snapshot_file.write(content)


def execute_command(command):
    print(' '.join(command))
    return subprocess.check_output(command).decode('utf-8')


rojo_output = execute_command([
    'rojo',
    'build',
    ROJO_PROJECT_FILE,
    '-o',
    TEST_PLACE_FILE_NAME,
])

print(rojo_output)

output = execute_command([
    'run-in-roblox',
    TEST_PLACE_FILE_NAME,
    '-s',
    TEST_FILE,
    '-t',
    '60',
])

print(pattern.sub('', output))

for match in pattern.finditer(output):
    name = match.group('name')
    content = match.group('content')
	write_snapshot_file(name, content)
```