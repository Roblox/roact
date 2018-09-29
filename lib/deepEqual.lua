--[[
	A utility used to assert that two tables are equal recursively in tests.

	This should only be used in tests.
]]

local function deepEqual(a, b)
	if typeof(a) ~= typeof(b) then
		return false
	end

	if typeof(a) == "table" then
		local visitedKeys = {}

		for key, value in pairs(a) do
			visitedKeys[key] = true

			if not deepEqual(value, b[key]) then
				return false
			end
		end

		for key, value in pairs(b) do
			if not visitedKeys[key] then
				if not deepEqual(value, a[key]) then
					return false
				end
			end
		end

		return true
	else
		return a == b
	end
end

return deepEqual