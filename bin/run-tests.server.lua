local ReplicatedStorage = game:GetService("ReplicatedStorage")
local isRobloxCli, ProcessService = pcall(game.GetService, game, "ProcessService")

local Roact = require(ReplicatedStorage.Roact)
local TestEZ = require(ReplicatedStorage.TestEZ)

Roact.setGlobalConfig({
	["internalTypeChecks"] = true,
	["typeChecks"] = true,
	["elementTracing"] = true,
	["propValidation"] = true,
})
local results = TestEZ.TestBootstrap:run(
	{ ReplicatedStorage.Roact },
	TestEZ.Reporters.TextReporter
)

local statusCode = (results.failureCount == 0 and #results.errors == 0) and 0 or 1

if _G.__LEMUR__ then
	os.exit(statusCode)
elseif isRobloxCli then
	ProcessService:ExitAsync(statusCode)
end
