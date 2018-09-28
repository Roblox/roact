--[[
	Reference renderer intended for use in tests as well as for documenting the
	minimum required interface for a Roact renderer.
]]

local NoopRenderer = {}

function NoopRenderer.mountHostNode(reconciler, node)
end

function NoopRenderer.unmountHostNode(reconciler, node)
end

function NoopRenderer.updateHostNode(reconciler, node, newElement)
	return node
end

return NoopRenderer