local Type = require(script.Parent.Type)

local function noop()
	return nil
end

local ChildUtils = {}

ChildUtils.UseParentKey = {}

function ChildUtils.iterateChildren(elements)
	local richType = Type.of(elements)

	-- Single child, the simplest case!
	if richType == Type.Element then
		local called = false

		return function()
			if called then
				return nil
			else
				called = true
				return ChildUtils.UseParentKey, elements
			end
		end
	end

	-- This is a Roact-speciifc object, and it's the wrong kind.
	if richType ~= nil then
		error("Invalid children")
	end

	local regularType = typeof(elements)

	-- A dictionary of children, hopefully!
	-- TODO: Is this too flaky? Should we introduce a Fragment type like React?
	if regularType == "table" then
		return pairs(elements)
	end

	if elements == nil or regularType == "boolean" then
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