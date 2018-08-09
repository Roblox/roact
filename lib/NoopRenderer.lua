local Core = require(script.Parent.Core)

local NoopRenderer = {}

function NoopRenderer.mountHostNode(reconciler, node, element, hostParent, key)
end

function NoopRenderer.unmountHostNode(reconciler, node)
end

function NoopRenderer.updateHostNode(reconciler, node, newElement)
	reconciler.updateNodeChildren(node, newElement.props[Core.Children])

	return node
end

return NoopRenderer