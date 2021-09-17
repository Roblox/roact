--[[
	Contains deprecated methods from Reconciler. Broken out so that removing
	this shim is easy -- just delete this file and remove it from init.
]]

local Logging = require(script.Parent.Logging)

local reifyMessage = [[
Roact.reify has been renamed to Roact.mount and will be removed in a future release.
Check the call to Roact.reify at:
]]

local teardownMessage = [[
Roact.teardown has been renamed to Roact.unmount and will be removed in a future release.
Check the call to Roact.teardown at:
]]

local reconcileMessage = [[
Roact.reconcile has been renamed to Roact.update and will be removed in a future release.
Check the call to Roact.reconcile at:
]]

local function createReconcilerCompat(reconciler)
	local compat = {}

	function compat.reify(...)
		Logging.warnOnce(reifyMessage)

		return reconciler.mountVirtualTree(...)
	end

	function compat.teardown(...)
		Logging.warnOnce(teardownMessage)

		return reconciler.unmountVirtualTree(...)
	end

	function compat.reconcile(...)
		Logging.warnOnce(reconcileMessage)

		return reconciler.updateVirtualTree(...)
	end

	return compat
end

return createReconcilerCompat
