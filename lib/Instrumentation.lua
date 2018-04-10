local GlobalConfig = require(script.Parent.GlobalConfig)

local Instrumentation = {}

local ComponentStats = {}
-- Tracks HELLA stats, including:
	-- Recorded stats:
		-- Render count by component
		-- Update request count by component
		-- Actual update count by component
		-- shouldUpdate returned true count by component
		-- Time taken to run shouldUpdate
		-- Time taken to render by component
	-- Derived stats:
		-- Average render time by component
		-- Percent of total render time by component
		-- Average shouldUpdate time by component
		-- Percent of time shouldUpdate returns true
		-- Percent of total shouldUpdate time by component

local function valuesByStat(t, f)
	local a = {}
	for _, obj in pairs(t) do table.insert(a, obj) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i]
		end
	end
	return iter
end

local function getStatEntry(handle)
	local name
	if handle and handle._element and handle._element.component then
		name = tostring(handle._element.component)
	else
		warn("Component name not valid for " .. tostring(handle._key))
		return nil
	end
	local entry = ComponentStats[name]
	if not entry then
		-- Use shortened name for convenience; 
		local shortName = name:gsub("Connection","Conn")
		shortName = shortName:gsub("Localize","Loc")
		shortName = shortName:gsub("FitChildren","FitCh")
		entry = {
			-- store semi-redundant name field for easier sorting
			component = shortName,
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
		ComponentStats[name] = entry
	end

	return entry
end

function Instrumentation.logShouldUpdate(handle, updateNeeded, shouldUpdateTime)
	-- Make sure entry exists in stats object
	local statEntry = getStatEntry(handle)
	if statEntry then
		-- Record result
		statEntry.updateReqCount = statEntry.updateReqCount + 1
		statEntry.didUpdateCount = statEntry.didUpdateCount + (updateNeeded and 1 or 0)
		statEntry.shouldUpdateTime = statEntry.shouldUpdateTime + shouldUpdateTime * 1000
	end
end

function Instrumentation.logRenderTime(handle, renderTime)
	-- Make sure entry exists in stats object
	local statEntry = getStatEntry(handle)
	if statEntry then
		-- Add the result to the collected stats
		statEntry.renderCount = statEntry.renderCount + 1
		-- Render time should be in millis
		statEntry.renderTime = statEntry.renderTime + renderTime * 1000
	end
end

function Instrumentation.printStats(sortBy)
	sortBy = sortBy or "component"

	local trackUpdates = GlobalConfig.getValue("shouldUpdateInstrumentation")
	local trackRenders = GlobalConfig.getValue("renderInstrumentation")

	if not trackUpdates and not trackRenders then
		print("No stats are being tracked!  Enable with Roact.setConfig({...})")
		return
	end

	local totalRenderTime, totalShouldUpdateTime = 0, 0

	-- For each of the tracked stats, aggregate them into overall stats
	for _, stat in pairs(ComponentStats) do
		totalRenderTime = totalRenderTime + stat.renderTime
		totalShouldUpdateTime = totalShouldUpdateTime + stat.shouldUpdateTime
	end

	-- Get derived stats
	for _, stat in pairs(ComponentStats) do
		stat.avgRenderTime = stat.renderTime / stat.renderCount
		stat.avgShouldUpdateTime = (stat.updateReqCount > 0) and (stat.shouldUpdateTime / stat.updateReqCount) or 0
		stat.renderPct = stat.renderTime / totalRenderTime * 100
		stat.updateFreq = (stat.updateReqCount > 0) and (stat.didUpdateCount / stat.updateReqCount * 100) or 0
		stat.updatePct = stat.shouldUpdateTime / totalShouldUpdateTime * 100
	end

	-- Set up sort function based on specified stat
	local compare = function(a, b)
		return a[sortBy] < b[sortBy]
	end

	-- Print column headers
	local colHeaders = ("%-30s"):format("Component Name")
	if trackUpdates then
		colHeaders = colHeaders .. (
			"%-12s%-12s%-12s%-12s%-12s"
		):format(
			"Update Reqs",
			"Updates",
			"Avg Time",
			"Update %",
			"U Time %"
		)
	end
	if trackRenders then
		colHeaders = colHeaders .. (
			"%-12s%-12s%-12s"
		):format(
			"Renders",
			"Avg Time",
			"R Time %"
		)
	end
	print(colHeaders)

	-- Print stat rows
	for stat in valuesByStat(ComponentStats, compare) do
		local statsRow = ("%-30s"):format(stat.component)
		if trackUpdates then
			statsRow = statsRow .. (
				"%-12d%-12d%-12.3f%-12.3f%-12.3f"
			):format(
				stat.updateReqCount,
				stat.didUpdateCount,
				stat.avgShouldUpdateTime,
				stat.updateFreq,
				stat.updatePct
			)
		end
		if trackRenders then
			statsRow = statsRow .. (
				"%-12d%-12.3f%-12.3f"
			):format(
				stat.renderCount,
				stat.avgRenderTime,
				stat.renderPct
			)
		end
		print(statsRow)
	end
	if trackUpdates then
		print(("Total time shouldUpdating: %.2fms"):format(totalShouldUpdateTime))
	end
	if trackRenders then
		print(("Total time rendering: %.2fms"):format(totalRenderTime))
	end
end

return Instrumentation