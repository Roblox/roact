local DebugTrackWastedRenders = {}

-- Tracks total number of renders by type of component
local totalRenders = 0
local wastedRendersByType = {}
local validRendersByType = {}

-- Allows tracking of frames without renders, so we can only report when needed
local previousTotal = 0
local framesWithoutUpdate = 0
-- TODO: Make this configurable somehow without overcomplicating GlobalConfig
local renderFramesTillSettled = 10

local HeartbeatConnection = nil

--[[
	Determine if an old and new elements are equal. Used to detect wasted renders
	when the trackWastedRenders flag is set
]]
local function deepEquals(old, new)
	if old == new then
		return true
	end

	if (type(old) == "table" and type(new) == "table") then
		for key, oldVal in pairs(old) do
			if not deepEquals(new[key], oldVal) then
				return false
			end
		end

		for key, newVal in pairs(new) do
			if not deepEquals(newVal, old[key]) then
				return false
			end
		end
	else
		return false
	end

	return true
end


--[[
	Print accumulated wasted render stats once the number of renders stops increasing
	for the amount of frames specified in the config
]]
local function printStatsWhenSettled()
	if previousTotal == totalRenders then
		framesWithoutUpdate = framesWithoutUpdate + 1

		-- If it's been enough frames without new Roact Renders, report results
		if framesWithoutUpdate == renderFramesTillSettled then
			-- TODO: More precise/accurate messaging, better spacing
			-- Print stats on wasted renders
			print("UI settled. Render stats:")
			for type, _ in pairs(wastedRendersByType) do
				local wasted = wastedRendersByType[type]
				local valid = validRendersByType[type]
				if wasted > 0 or valid > 0 then
					print((
						"	%s: %d wasted, %d valid; Amount valid = %d%%"
					):format(type, wasted, valid, valid / (wasted + valid) * 100))
				end
			end
			-- Clear the wasted render data
			totalRenders = 0

			for k, _ in pairs(wastedRendersByType) do
				wastedRendersByType[k] = 0
				validRendersByType[k] = 0
			end
		end
	else
		-- Reset the counter as long as renders are still happening
		framesWithoutUpdate = 0
	end
	previousTotal = totalRenders
end

--[[
	Start start reporting wasted renders whenever Roact settles
]]
function DebugTrackWastedRenders.startReporting()
	HeartbeatConnection = game:GetService("RunService").Heartbeat:connect(function()
		printStatsWhenSettled()
	end)
end

--[[
	Stop reporting. Note that this doesn't affect whether or not wasted renders are tracked
]]
-- TODO: Find out if/where this should be called, possibly better align tracking and reporting
function DebugTrackWastedRenders.stopReporting()
	if HeartbeatConnection then
		HeartbeatConnection:Disconnect()
		HeartbeatConnection = nil
	end
end

--[[
	When Roact renders an element, it will report it via this method. If the
	new element is equivalent to the old one, we consider it a wasted render
]]
function DebugTrackWastedRenders.recordRender(type, newElement, oldElement)
	totalRenders = totalRenders + 1
	if deepEquals(oldElement, newElement) then
		wastedRendersByType[type] = (wastedRendersByType[type] or 0) + 1
	else
		validRendersByType[type] = (validRendersByType[type] or 0) + 1
	end
end

return DebugTrackWastedRenders