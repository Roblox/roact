local optionsTypes = {
	depth = "number",
}

local function validateShallowOptions(options)
	if options == nil then
		return true
	end

	for key, value in pairs(options) do
		local expectType = optionsTypes[key]

		if expectType == nil then
			return false, ("unexpected option field %q (with value of %s)"):format(
				tostring(key),
				tostring(value)
			)
		elseif typeof(value) ~= expectType then
			return false, ("unexpected option type for %q (expected %s but got %s)"):format(
				tostring(key),
				expectType,
				typeof(value)
			)
		end
	end

	return true
end

return validateShallowOptions