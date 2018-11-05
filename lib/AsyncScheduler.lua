local AsyncScheduler = {}
AsyncScheduler.__index = AsyncScheduler

function AsyncScheduler.new(reconciler)
	local self = {
		reconciler = reconciler,
		virtualNodesToUpdates = {},
		updateQueue = {},
	}
	setmetatable(self, AsyncScheduler)

	return self
end

function AsyncScheduler:scheduleUnmount(virtualNode)
	self.virtualNodesToUpdates[virtualNode] = {
		unmount = true,
	}
end

function AsyncScheduler:scheduleUpdate(virtualNode, newElement, newState)
	local existing = self.virtualNodesToUpdates[virtualNode]

	if existing == nil then
		existing = {}
		self.virtualNodesToUpdates[virtualNode] = existing
	end

	if newElement ~= nil then
		existing.newElement = newElement
	end

	if newState ~= nil then
		existing.newState = newState
	end
end

function AsyncScheduler:applyUpdates()
	for virtualNode, update in pairs(self.virtualNodesToUpdates) do
		if update.unmount then
			self.reconciler.unmountVirtualNode(virtualNode)
		else
			self.reconciler.updateVirtualNode(virtualNode, update.newElement, update.newState)
		end
	end
end

return AsyncScheduler