--[[
	Dependencies added here will be installed into the `modules` folder.

	It should be run from the project directory, like:

		lua bin/install-dependencies.lua
]]

local dependencies = {
	lemur = {
		git = "https://github.com/LPGhatguy/lemur.git",
		version = "v0.1.0",
	},
	testez = {
		git = "https://github.com/Roblox/TestEZ.git",
		version = "master",
	},
}

local lfs = require("lfs")

lfs.mkdir("modules")
assert(lfs.chdir("modules"))

for name, dependency in pairs(dependencies) do
	os.execute(("git clone --depth=1 %s %s"):format(
		dependency.git,
		name
	))

	assert(lfs.chdir(name))
	os.execute(("git checkout %s"):format(
		dependency.version
	))

	assert(lfs.chdir(".."))
end