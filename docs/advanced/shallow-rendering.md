Shallow rendering is when you mount only a certain part an element tree. Technically, Roact does not provide the ability to shallow render a tree yet, but you can obtain a ShallowWrapper object that will mimic how shallow rendering works.

## ShallowWrapper

When writing tests for Roact components, you can mount your component using `Roact.mount` and then retrieve a ShallowWrapper object from the returned `VirtualTree`.

```lua
-- let's assume there is a ComponentToTest that we want to test

local virtualTree = Roact.mount(ComponentToTest)

local shallowWrapper = tree:getShallowWrapper()
```

The ShallowWrapper is meant to provide an interface to help make assertions about behavior you expect from your component.

---

## Snapshot Tests

### What are Snapshots

Snapshots are files that contains serialized data. In Roact's case, snapshots of ShallowWrapper objects can be generated. More specifically, the data contained from a ShallowWrapper is converted to Lua code, which is then saved into a ModuleScript.

!!! Note
	Currently, the generated snapshot will be stored in a StringValue. Often, the permission level where the test are ran does not make it possible to create a ModuleScript and assign it's Source property. For now, we rely on other tools like Roact's SnapshotsPlugin to copy the generated StringValue from Run mode to ModuleScript in Edit mode.

During the tests execution, these snapshots are used to verify that they do not change through time.

---

### What are Snapshot Tests

The goal of snapshot tests is to make sure that the current serialized version of a snapshot matches the new generated one. This can be done through the `matchSnapshot` method on the ShallowWrapper. The string passed to the method will be to find the previous snapshot.

```lua
shallowWrapper:matchSnapshot("ComponentToTest")
```

Here is a break down of what happen behind this method.

1. Check if there is an existing snapshot with the given name.
2. If no snapshot exists, generate a new one from the ShallowWrapper and exit, otherwise continue
3. Require the ModuleScript (the snapshot) to obtain the table containing the data
4. Compare the loaded data with the generated data from the ShallowWrapper
5. Throw an error if the data is different from the loaded one

---

###

### Where Snapshot Tests Are Good

Snapshot tests really shine when comes the time to test for regression.

---

### Where Snapshot Tests Are Bad

---

## Managing Snapshots

### Within Roblox Studio

When the tests are executed in Run mode (after Run is pressed), the snapshots are going to be created as StringValue objects inside a folder (ReplicatedStorage.RoactSnapshots). Then, pressing Stop to go back edit the place will delete all the new created snapshots values. In order to keep those values, a special plugin is needed to serialize the RoactSnapshots content into a plugin setting. Once the place go back in edit mode, the same plugin will detect the new content in the setting value and recreate the snapshots as ModuleScript objects.



---

### On the File System

Some users might be using a tool like `rojo` to sync files to Roblox Studio. To work with snapshots, something will be needed to sync the generated files from Roblox Studio to the file system.

[`run-in-roblox`](https://github.com/LPGhatguy/run-in-roblox/) is [`Rust`](https://www.rust-lang.org/) project that allow Roblox to be run from the command line and sends the Roblox output content to the shell window. Using this tool, a script can be written to execute studio with a specific test runner that will print out the new snapshots in a special format. Then, the output can be parsed to find the new snapshots and write them to files.

You can find these scripts written in Lua ([link](../scripts/sync-snapshots-with-lua.md)) or in python ([link](../scripts/sync-snapshots-with-python.md)) (compatible with version 2 and 3). These scripts will assume that you have the rojo and run-in-roblox commands available. They contain the same functionalities: it builds a place from a rojo configuration file, then it runs a specific script inside studio that should print the snapshots. The output is parsed to find the snapshots and write them.
