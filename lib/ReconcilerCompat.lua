--[[
	Contains deprecated methods from Reconciler. Broken out so that removing
	this shim is easy -- just delete this file and remove it from init.
]]

local Reconciler = require(script.Parent.Reconciler)

local warnedLocations = {}

local reifyMessage = [[
Roact.reify has been renamed to Roact.mount and will be removed in a future release.
Check the call to Roact.reify at:
]]

local teardownMessage = [[
Roact.teardown has been renamed to Roact.unmount and will be removed in a future release.
Check the call to Roact.teardown at:
]]

local ReconcilerCompat = {}

--[[
	Exposed as a method so that test cases can override `warn`.
]]
ReconcilerCompat._warn = warn

local function warnOnce(message)
	local trace = debug.traceback(message, 3)
	if warnedLocations[trace] then
		return
	end

	warnedLocations[trace] = true

	ReconcilerCompat._warn(trace)
end

function ReconcilerCompat.reify(...)
	warnOnce(reifyMessage)

	return Reconciler.mount(...)
end

function ReconcilerCompat.teardown(...)
	warnOnce(teardownMessage)

	return Reconciler.unmount(...)
end

return ReconcilerCompat