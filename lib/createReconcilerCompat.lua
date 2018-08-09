--[[
	Contains deprecated methods from Reconciler. Broken out so that removing
	this shim is easy -- just delete this file and remove it from init.
]]

local warnedLocations = {}

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
Check the clal to Roact.reconcile at:
]]

local function createReconcilerCompat(reconciler, warnOverride)
	if warnOverride == nil then
		warnOverride = warn
	end

	local compat = {}

	local function warnOnce(message)
		local trace = debug.traceback(message, 3)
		if warnedLocations[trace] then
			return
		end

		warnedLocations[trace] = true

		warnOverride(trace)
	end

	function compat.reify(...)
		warnOnce(reifyMessage)

		return reconciler.mountTree(...)
	end

	function compat.teardown(...)
		warnOnce(teardownMessage)

		return reconciler.unmountTree(...)
	end

	function compat.reconcile(...)
		warnOnce(reconcileMessage)

		return reconciler.updateTree(...)
	end

	return compat
end

return createReconcilerCompat