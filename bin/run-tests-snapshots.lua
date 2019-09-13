-- luacheck: globals __LEMUR__

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Roact = require(ReplicatedStorage.Roact)
local TestEZ = require(ReplicatedStorage.TestEZ)

Roact.setGlobalConfig({
	["internalTypeChecks"] = true,
	["typeChecks"] = true,
	["elementTracing"] = true,
	["propValidation"] = true,
})
local results = TestEZ.TestBootstrap:run(ReplicatedStorage.Roact, TestEZ.Reporters.TextReporter)

local RoactSnapshots = ReplicatedStorage:WaitForChild("RoactSnapshots", 1)

if not RoactSnapshots then
    return nil
end

for _, snapshot in pairs(RoactSnapshots:GetChildren()) do
    if snapshot:IsA("StringValue") then
        print(("Snapshot:::<|%s|><|=>%s<=|>"):format(snapshot.Name, snapshot.Value))
    end
end