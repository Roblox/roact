local RunService = game:GetService("RunService")

local EditModeMain = require(script.EditModeMain)
local RunModeMain = require(script.RunModeMain)

if RunService:IsEdit() then
	EditModeMain(plugin)
else
	if RunService:IsClient() then
		RunModeMain(plugin)
	end
end