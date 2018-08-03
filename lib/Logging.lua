local outputEnabled = true
local collectors = {}

local function createLogInfo()
	local logInfo = {
		warnings = {},
	}

	setmetatable(logInfo, {
		__tostring = function(self)
			return ("LogInfo\n\tWarnings (%d):\n\t\t%s"):format(
				#self.warnings,
				table.concat(self.warnings, "\n\t\t")
			)
		end,
	})

	return logInfo
end

local Logging = {}

function Logging.capture(callback)
	local collector = createLogInfo()

	local wasOutputEnabled = outputEnabled
	outputEnabled = false
	collectors[collector] = true

	local success, result = pcall(callback)

	collectors[collector] = nil
	outputEnabled = wasOutputEnabled

	assert(success, result)

	return collector
end

function Logging.warn(message)
	for collector in pairs(collectors) do
		table.insert(collector.warnings, message)
	end

	if outputEnabled then
		warn(message)
	end
end

return Logging