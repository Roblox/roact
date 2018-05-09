--[[
	Contains deprecated methods from Reconciler. Broken out so that removing
	this shim is easy -- just delete this file and remove it from init.
]]

local Reconciler = require(script.Parent.Reconciler)

local ReconcilerCompat = {}

function ReconcilerCompat.reify(...)
	return Reconciler.mount(...)
end

function ReconcilerCompat.teardown(...)
	return Reconciler.unmount(...)
end

return ReconcilerCompat