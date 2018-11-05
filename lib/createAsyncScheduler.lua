local function createAsyncScheduler(reconciler)
	local virtualNodesToUpdates = {}

	local function scheduleUnmountVirtualNode(virtualNode)
		virtualNodesToUpdates[virtualNode] = {
			unmount = true,
		}
	end

	local function scheduleUpdateVirtualNode(virtualNode, newElement, newState)
		local existing = virtualNodesToUpdates[virtualNode]

		if existing == nil then
			existing = {}
			virtualNodesToUpdates[virtualNode] = existing
		end

		if newElement ~= nil then
			existing.newElement = newElement
		end

		if newState ~= nil then
			existing.newState = newState
		end
	end

	local function applyUpdates()
		for virtualNode, update in pairs(virtualNodesToUpdates) do
			if update.unmount then
				reconciler.unmountVirtualNode(virtualNode)
			else
				reconciler.updateVirtualNode(virtualNode, update.newElement, update.newState)
			end
		end
	end

	return {
		scheduleUpdateVirtualNode = scheduleUpdateVirtualNode,
		scheduleUnmountVirtualNode = scheduleUnmountVirtualNode,
		applyUpdates = applyUpdates,
	}
end

return createAsyncScheduler