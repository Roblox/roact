--[[
	A utility used to assert that two objects are value-equal recursively. It
	outputs fairly nicely formatted messages to help diagnose why two objects
	would be different.

	This should only be used in tests.
]]

local function deepEqual(a, b)
	if typeof(a) ~= typeof(b) then
		local message = string.format(
			"{1} is of type %s, but {2} is of type %s",
			typeof(a),
			typeof(b)
		)

		return false, message
	end

	if typeof(a) == "table" then
		local visitedKeys = {}

		for key, value in pairs(a) do
			visitedKeys[key] = true

			local success, innerMessage = deepEqual(value, b[key])
			if not success then
				local message = string.gsub(
					string.gsub(innerMessage, "{1}", string.format("{1}[%s]", tostring(key))),
					"{2}",
					string.format("{2}[%s]", tostring(key))
				)

				return false, message
			end
		end

		for key, value in pairs(b) do
			if not visitedKeys[key] then
				local success, innerMessage = deepEqual(value, a[key])

				if not success then
					local message = string.gsub(
						string.gsub(innerMessage, "{1}", string.format("{1}[%s]", tostring(key))),
						"{2}",
						string.format("{2}[%s]", tostring(key))
					)

					return false, message
				end
			end
		end

		return true
	end

	if a == b then
		return true
	end

	local message = "{1} ~= {2}"
	return false, message
end

local function assertDeepEqual(a, b)
	local success, innerMessageTemplate = deepEqual(a, b)

	if not success then
		local innerMessage = string.gsub(string.gsub(innerMessageTemplate, "{1}", "first"), "{2}", "second")

		local message = string.format("Values were not deep-equal.\n%s", innerMessage)

		error(message, 2)
	end
end

return assertDeepEqual