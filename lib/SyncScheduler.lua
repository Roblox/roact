local SyncScheduler = {}
SyncScheduler.__index = SyncScheduler

function SyncScheduler.new(reconciler)
	local self = {
		reconciler = reconciler,
	}

	setmetatable(self, SyncScheduler)

	return self
end

function SyncScheduler:scheduleUnmount(virtualNode)
	self.reconciler.unmountVirtualNode(virtualNode)
end

function SyncScheduler:scheduleUpdate(virtualNode, newElement, newState)
	self.reconciler.updateVirtualNode(virtualNode, newElement, newState)
end

function SyncScheduler:applyUpdates()
end

return SyncScheduler