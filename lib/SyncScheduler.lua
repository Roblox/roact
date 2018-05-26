local SyncScheduler = {}
SyncScheduler.__index = SyncScheduler

function SyncScheduler.new()
	local self = setmetatable({}, SyncScheduler)

	return self
end

function SyncScheduler:schedule(task)
	task()
end

function SyncScheduler:destruct()
end

function SyncScheduler:flush()
end

return SyncScheduler