local NoopRenderer = {}

function NoopRenderer.mountHostNode(reconciler, node, element, hostParent, key)
end

function NoopRenderer.unmountHostNode(reconciler, node)
end

function NoopRenderer.reconcileHostNode(reconciler, node, newElement)
	return node
end

return NoopRenderer