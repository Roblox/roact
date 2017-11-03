--[[
	Debugging assistance module for Roact.

	Exposed as Roact.Unstable.Debug; it's a work in progress and thus unstable.
]]

local Core = require(script.Parent.Core)

local INDENT = ".   "

local Debug = {}

function Debug.visualize(instance)
	local buffer = {}
	Debug._visualize(instance, 0, buffer)

	return table.concat(buffer, "\n")
end

function Debug._visualize(instance, indentLevel, buffer)
	local entry = ("%s%s: %s"):format(
		INDENT:rep(indentLevel),
		tostring(instance._element.type),
		instance._key
	)

	table.insert(buffer, entry)

	if Core.isPrimitiveElement(instance._element) then
		for _, child in pairs(instance._reifiedChildren) do
			Debug._visualize(child, indentLevel + 1, buffer)
		end
	elseif Core.isStatefulElement(instance._element) or Core.isFunctionalElement(instance._element) then
		if instance._reified then
			Debug._visualize(instance._reified, indentLevel + 1, buffer)
		end
	end
end

return Debug