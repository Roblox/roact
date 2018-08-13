local Type = require(script.Parent.Type)

local function noop()
	return nil
end

local ChildUtils = {}

ChildUtils.UseParentKey = {}

function ChildUtils.iterateChildren(childrenOrChild)
	local richType = Type.of(childrenOrChild)

	-- Single child, the simplest case!
	if richType ~= nil then
		local called = false

		return function()
			if called then
				return nil
			else
				called = true
				return ChildUtils.UseParentKey, childrenOrChild
			end
		end
	end

	local regularType = typeof(childrenOrChild)

	-- A dictionary of children, hopefully!
	-- TODO: Is this too flaky? Should we introduce a Fragment type like React?
	if regularType == "table" then
		return pairs(childrenOrChild)
	end

	if childrenOrChild == nil or regularType == "boolean" then
		return noop
	end

	error("Invalid children")
end

function ChildUtils.getChildByKey(elements, key)
	if elements == nil or typeof(elements) == "boolean" then
		return nil
	end

	if Type.of(elements) == Type.Element then
		if key == ChildUtils.UseParentKey then
			return elements
		end

		return nil
	end

	return elements[key]
end

return ChildUtils