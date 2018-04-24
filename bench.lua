--[[
	Loads our library and all of its dependencies, then run a set of benchmarks.
]]

-- If you add any dependencies, add them to this table so they'll be loaded!
local LOAD_MODULES = {
	{"lib", "Roact"},
}

-- This makes sure we can load Lemur and other libraries that depend on init.lua
package.path = package.path .. ";?/init.lua"

-- If this fails, make sure you've run `lua bin/install-dependencies.lua` first!
local lemur = require("modules.lemur")

--[[
	Collapses ModuleScripts named 'init' into their parent folders.

	This is the same behavior as the collapsing mechanism from rbxpacker.
]]
local function collapse(root)
	local init = root:FindFirstChild("init")
	if init then
		init.Name = root.Name
		init.Parent = root.Parent

		for _, child in ipairs(root:GetChildren()) do
			child.Parent = init
		end

		root:Destroy()
		root = init
	end

	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("Folder") then
			collapse(child)
		end
	end

	return root
end

-- Create a virtual Roblox tree
local habitat = lemur.Habitat.new()

-- We'll put all of our library code and dependencies here
local Root = habitat.game:GetService("ReplicatedStorage")

-- Load all of the modules specified above
for _, module in ipairs(LOAD_MODULES) do
	local container = lemur.Instance.new("Folder", Root)
	container.Name = module[2]
	habitat:loadFromFs(module[1], container)
end

local Benchmarks = lemur.Instance.new("Folder")
Benchmarks.Parent = Root
Benchmarks.Name = "Benchmarks"

habitat:loadFromFs("benchmarks", Benchmarks)
habitat:loadFromFs("benchmark-core.server.lua", Root)

collapse(Root)

habitat:require(Root:FindFirstChild("benchmark-core.server"))