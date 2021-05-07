local function strict(t, name)
	name = name or tostring(t)

	return setmetatable(t, {
		__index = function(_, key)
			local message = string.format(
				"%q (%s) is not a valid member of %s",
				tostring(key),
				typeof(key),
				name
			)

			error(message, 2)
		end,

		__newindex = function(_, key)
			local message = string.format(
				"%q (%s) is not a valid member of %s",
				tostring(key),
				typeof(key),
				name
			)

			error(message, 2)
		end,
	})
end

return strict