local SyncScheduler = {}
SyncScheduler.__index = SyncScheduler

function SyncScheduler.new(reconciler)
	local self = {
		reconciler = reconciler,
	}

	setmetatable(self, SyncScheduler)

	return self
end

function SyncScheduler:scheduleUnmountVirtualNode(virtualNode)
	self.reconciler.unmountVirtualNode(virtualNode)
end

function SyncScheduler:scheduleUpdateVirtualNode(virtualNode, newElement, newState)
	self.reconciler.updateVirtualNode(virtualNode, newElement, newState)
end

function SyncScheduler:applyUpdates()
end

return SyncScheduler