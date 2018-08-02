local function createSpy(inner)
	local self = {
		callCount = 0,
		values = {},
		valuesLength = 0,
	}

	self.value = function(...)
		self.callCount = self.callCount + 1
		self.values = {...}
		self.valuesLength = select("#", ...)

		if inner ~= nil then
			return inner(...)
		end
	end

	self.assertCalledWith = function(_, ...)
		local len = select("#", ...)

		assert(self.valuesLength, len, "length of expected values differs from stored values")

		for i = 1, len do
			local expected = select(i, ...)

			assert(self.values[i] == expected, "value differs")
		end
	end

	self.captureValues = function(_, ...)
		local len = select("#", ...)
		local result = {}

		assert(self.valuesLength, len, "length of expected values differs from stored values")

		for i = 1, len do
			local key = select(i, ...)
			result[key] = self.values[i]
		end

		return result
	end

	setmetatable(self, {
		__index = function(_, key)
			error(("%q is not a valid member of spy"):format(key))
		end,
	})

	return self
end

return createSpy