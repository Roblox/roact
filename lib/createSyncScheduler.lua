local function createSyncScheduler(reconciler)
	local function scheduleUnmountVirtualNode(virtualNode)
		reconciler.unmountVirtualNode(virtualNode)
	end

	local function scheduleUpdateVirtualNode(virtualNode, newElement, newState)
		reconciler.updateVirtualNode(virtualNode, newElement, newState)
	end

	local function scheduleUnmountVirtualTree(tree)
		scheduleUnmountVirtualNode(tree.rootNode)
	end

	local function scheduleUpdateVirtualTree(tree, newElement)
		scheduleUpdateVirtualTree(tree.rootNode, newElement)
	end

	local function applyUpdates()
	end

	return {
		scheduleUpdateVirtualNode = scheduleUpdateVirtualNode,
		scheduleUnmountVirtualNode = scheduleUnmountVirtualNode,
		scheduleUpdateVirtualTree = scheduleUpdateVirtualTree,
		scheduleUnmountVirtualTree = scheduleUnmountVirtualTree,
		applyUpdates = applyUpdates,
	}
end

return createSyncScheduler