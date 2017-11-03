local lemur = require("modules.lemur")

local habitat = lemur.Habitat.new()

local Roact = lemur.Instance.new("Folder")
Roact.Name = "Roact"
habitat:loadFromFs("lib", Roact)

-- Simulate rbxpacker's 'collapse' mechanism
do
	local newRoot = Roact:FindFirstChild("init")
	newRoot.Name = Roact.Name
	newRoot.Parent = nil

	for _, child in ipairs(Roact:GetChildren()) do
		child.Parent = newRoot
	end

	Roact = newRoot
end

local TestEZ = lemur.Instance.new("Folder")
TestEZ.Name = "TestEZ"
habitat:loadFromFs("modules/testez/lib", TestEZ)

local TestBootstrap = habitat:require(TestEZ.TestBootstrap)
local TextReporter = habitat:require(TestEZ.Reporters.TextReporter)

local results = TestBootstrap:run(Roact, TextReporter)

if results.failureCount > 0 then
	os.exit(1)
end