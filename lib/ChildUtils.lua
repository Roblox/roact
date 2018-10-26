local Type = require(script.Parent.Type)
local Symbol = require(script.Parent.Symbol)

local function noop()
	return nil
end

local ChildUtils = {}

--[[
	A signal value indicating that a child should use its parent's key, because
	it has no key of its own.

	This occurs when you return only one element from a function component or
	stateful render function.
]]
ChildUtils.UseParentKey = Symbol.named("UseParentKey")

--[[
	Returns an iterator over the children of an element.
	`childrenOrChild` may be one of:
	* a boolean
	* nil
	* a single element
	* a table of elements

	If `childrenOrChild` is a boolean or nil, this will return an iterator with
	zero elements.

	If `childrenOrChild` is a single element, this will return an iterator with
	one element: a tuple where the first value is ChildUtils.UseParentKey, and
	the second is the value of `childrenOrChild`.

	If `childrenOrChild` is a table, this will return an iterator over all the
	elements of the array, equivalent to `pairs(childrenOrChild)`.

	If `childrenOrChild` is none of the above, this function will throw.
]]
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

--[[
	Gets the child corresponding to a given key, respecting Roact's rules for
	children. Specifically:
	* If `elements` is nil or a boolean, this will return `nil`, regardless of
		the key given.
	* If `elements` is a single element, this will return `nil`, unless the key
		is ChildUtils.UseParentKey.
	* If `elements` is a table of elements, this will return `elements[key]`.
]]
function ChildUtils.getChildByKey(elements, hostKey)
	if elements == nil or typeof(elements) == "boolean" then
		return nil
	end

	if Type.of(elements) == Type.Element then
		if hostKey == ChildUtils.UseParentKey then
			return elements
		end

		return nil
	end

	return elements[hostKey]
end

return ChildUtils