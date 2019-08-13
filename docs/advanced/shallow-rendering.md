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

!!! Note
	For those using [luacheck](https://github.com/mpeterv/luacheck/) to analyse their Lua files, make sure to run the tool on the generated files. The format of the generated snapshots will probably fail luacheck (often just because of unused variables). There are no advantage to have these files match a specific format.

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
5. Throw an error if the data is different from the loaded one and generate a new ModuleScript that contains the new generated snapshot (useful for comparison)

---

#### Workflow Example

For a concrete example, suppose the following component (probably in a script named `ComponentToTest`).

```lua
local function ComponentToTest(props)
	return Roact.createElement("TextLabel", {
		Text = "foo",
	})
end
```

A snapshot test could be written this way (probably in a script named `ComponentToTest.spec`).

```lua
it("should match the snapshot", function()
	local element = Roact.createElement(ComponentToTest)
	local tree = Roact.mount(element)
	local shallowWrapper = tree:getShallowWrapper()

	shallowWrapper:matchSnapshot("ComponentToTest")
end)
```

After the first run, the test will have created a new script under `RoactSnapshots` called `ComponentToTest` that contains the following Lua code.

```lua
return function(dependencies)
  local Roact = dependencies.Roact
  local ElementKind = dependencies.ElementKind
  local Markers = dependencies.Markers

  return {
    type = {
      kind = ElementKind.Host,
      className = "TextLabel",
    },
    hostKey = "RoactTree",
    props = {
      Text = "foo",
    },
    children = {},
  }
end
```

Since these tests require the previous snapshots to compare with the current generated one, snapshots need to be committed to the version control software used for development. So the new component, the test and the generated snapshot would be commit and ready for review. The reviewer(s) will be able to review your snapshot as part of the normal review process.

Suppose now ComponentToTest needs a change. We update it to the following snippet.

```lua
local function ComponentToTest(props)
	return Roact.createElement("TextLabel", {
		Text = "bar",
	})
end
```

When we run back the previous test, it will fail and the message is going to tell us that the snapshots did not match. There will be a new script under `RoactSnapshots` called `ComponentToTest.NEW` that shows the new version of the snapshot.

```lua
return function(dependencies)
  local Roact = dependencies.Roact
  local ElementKind = dependencies.ElementKind
  local Markers = dependencies.Markers

  return {
    type = {
      kind = ElementKind.Host,
      className = "TextLabel",
    },
    hostKey = "RoactTree",
    props = {
      Text = "bar",
    },
    children = {},
  }
end
```

Since this example is trivial, it is easy to diff with human eyes and see that only the `Text` prop value changed from *foo* to *bar*. Since these changes are expected from the modification made to the component, we can delete the old snapshot and remove the `.NEW` from the newest one. If the tests are run again, they should all pass now.

Again, the updated snapshot will be committed to source control along with the component changes. That way, the reviewer will see exactly what changed in the snapshot, so they can make sure the changes are expected. But why go through all this process for such a trivial change?

Well, in most project complexity arise soon and components start to have more behavior. To make sure that certain behavior is not lost with a change, snapshot tests can assert that a button has a certain state after being clicked or while hovered.

---

#### Where They Are Good

##### Regression

Snapshot tests really shine when comes the time to test for regression.

##### Carefully Reviewed

Changes made to a snapshot file needs to be reviewed carefully as if it was hand written code. A reviewer needs to be able to catch any unexpected changes to a component. Any source control software should provide some way to see a diff of the changes that are going to be submitted. If a snapshot diff shows a difference of color property for a change that is supposed to update the sizing, the reviewer should point it to the developer and make sure the issue is solved because accepting the changes.

---

#### Where They Are Bad

##### Large Snapshots

If a snapshot is created from a top level component with a ShallowWrapper that renders deeply, it can produce a really large snapshot file with lots of details. What is bad with this snapshot, is that everytime a child of this component will change, the snapshot will fail.

This snapshot test will soon become an inconvenience and developers will slowly stop caring about it. The snapsot will not be reviewed correctly, because developers will be used to see the snapshot update on every new change submitted.

To avoid this situation, it is truly important that each snapshot is kept as simple and as small as possible. That is why the ShallowWrapper is deeply linked with the snapshot generation: it is needed to abstract the children of a component instead of making a snapshot that contains the whole tree.

---

## Managing Snapshots

### Within Roblox Studio

When the tests are executed in Run mode (after Run is pressed), the snapshots are going to be created as StringValue objects inside a folder (ReplicatedStorage.RoactSnapshots). Then, pressing Stop to go back edit the place will delete all the new created snapshots values. In order to keep those values, a special plugin is needed to serialize the RoactSnapshots content into a plugin setting. Once the place go back in edit mode, the same plugin will detect the new content in the setting value and recreate the snapshots as ModuleScript objects.

---

### On the File System

Some users might be using a tool like `rojo` to sync files to Roblox Studio. To work with snapshots, something will be needed to sync the generated files from Roblox Studio to the file system.

[`run-in-roblox`](https://github.com/LPGhatguy/run-in-roblox/) is [`Rust`](https://www.rust-lang.org/) project that allow Roblox to be run from the command line and sends the Roblox output content to the shell window. Using this tool, a script can be written to execute studio with a specific test runner that will print out the new snapshots in a special format. Then, the output can be parsed to find the new snapshots and write them to files.

You can find these scripts written in Lua ([link](../scripts/sync-snapshots-with-lua.md)) or in python ([link](../scripts/sync-snapshots-with-python.md)) (compatible with version 2 and 3). These scripts will assume that you have the rojo and run-in-roblox commands available. They contain the same functionalities: it builds a place from a rojo configuration file, then it runs a specific script inside studio that should print the snapshots. The output is parsed to find the snapshots and write them.
