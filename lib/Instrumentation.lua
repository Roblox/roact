--[[
	An optional instrumentation layer that the reconciler calls into to record
	various events.

	Tracks a number of stats, including:
		Recorded stats:
		- Render count by component
		- Update request count by component
		- Actual update count by component
		- shouldUpdate returned true count by component
		- Time taken to run shouldUpdate
		- Time taken to render by component
		Derivable stats (for profiling manually or with a future tool):
		- Average render time by component
		- Percent of total render time by component
		- Percent of time shouldUpdate returns true
		- Average shouldUpdate time by component
		- Percent of total shouldUpdate time by component
]]

local Instrumentation = {}

local componentStats = {}

--[[
	Determines name of component from the given instance handle and returns a
	stat object from the componentStats table, generating a new one if needed
]]
local function getStatEntry(handle)
	local name
	if handle and handle._element and handle._element.component then
		name = tostring(handle._element.component)
	else
		warn("Component name not valid for " .. tostring(handle._key))
		return nil
	end
	local entry = componentStats[name]
	if not entry then
		entry = {
			-- update requests
			updateReqCount = 0,
			-- actual updates
			didUpdateCount = 0,
			-- time spent in shouldUpdate
			shouldUpdateTime = 0,
			-- number of renders
			renderCount = 0,
			-- total render time spent
			renderTime = 0,
		}
		componentStats[name] = entry
	end

	return entry
end

--[[
	Logs the time taken and resulting value of a Component's shouldUpdate function
]]
function Instrumentation.logShouldUpdate(handle, updateNeeded, shouldUpdateTime)
	-- Grab or create associated entry in stats table
	local statEntry = getStatEntry(handle)
	if statEntry then
		-- Increment the total number of times update was invoked
		statEntry.updateReqCount = statEntry.updateReqCount + 1

		-- Increment (when applicable) total number of times shouldUpdate returned true
		statEntry.didUpdateCount = statEntry.didUpdateCount + (updateNeeded and 1 or 0)

		-- Add time spent checking if an update is needed (in millis) to total time
		statEntry.shouldUpdateTime = statEntry.shouldUpdateTime + shouldUpdateTime * 1000
	end
end

--[[
	Logs the time taken value of a Component's render function
]]
function Instrumentation.logRenderTime(handle, renderTime)
	-- Grab or create associated entry in stats table
	local statEntry = getStatEntry(handle)
	if statEntry then
		-- Increment total render count
		statEntry.renderCount = statEntry.renderCount + 1

		-- Add render time (in millis) to total rendering time
		statEntry.renderTime = statEntry.renderTime + renderTime * 1000
	end
end

--[[
	Clears all the stats collected thus far. Useful for testing and for profiling in the future
]]
function Instrumentation.clearCollectedStats()
	componentStats = {}
end

--[[
	Returns all the stats collected thus far. Useful for testing and for profiling in the future
]]
function Instrumentation.getCollectedStats()
	return componentStats
end

return Instrumentation