--[[
	Utility to retrieve one child out the children passed to a component.

	If passed nil or an empty table, will return nil.

	Throws an error if passed more than one child, but can be passed zero.
]]
local function oneChild(children)
	if not children then
		return
	end

	local key, child = next(children)

	if not child then
		return
	end

	local after = next(children, key)

	if after then
		error("Expected at most child, had more than one child.", 2)
	end

	return child
end

return oneChild