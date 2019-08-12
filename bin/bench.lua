--[[
	Loads our library and all of its dependencies, then run a set of benchmarks.
]]

-- If you add any dependencies, add them to this table so they'll be loaded!
local LOAD_MODULES = {
	{"src", "Roact"},
}

-- This makes sure we can load Lemur and other libraries that depend on init.lua
package.path = package.path .. ";?/init.lua"

-- If this fails, make sure you've cloned all Git submodules of this repo!
local lemur = require("modules.lemur")

-- Create a virtual Roblox tree
local habitat = lemur.Habitat.new()

-- We'll put all of our library code and dependencies here
local root = habitat.game:GetService("ReplicatedStorage")

-- Load all of the modules specified above
for _, module in ipairs(LOAD_MODULES) do
	local container = habitat:loadFromFs(module[1])
	container.Name = module[2]
	container.Parent = root
end

local runBenchMarks = habitat:loadFromFs("benchmarks/init.server.lua")
runBenchMarks.Name = "RoactBenchmark"
runBenchMarks.Parent = root

local benchmarks = habitat:loadFromFs("benchmarks")
benchmarks.Name = "Benchmarks"
benchmarks.Parent = runBenchMarks

habitat:require(runBenchMarks)