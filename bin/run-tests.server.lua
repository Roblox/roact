-- luacheck: globals __LEMUR__

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.TestEZ)
local results = TestEZ.TestBootstrap:run(ReplicatedStorage.Roact, TestEZ.Reporters.TextReporter)

if __LEMUR__ then
	if results.failureCount > 0 then
		os.exit(1)
	end
end