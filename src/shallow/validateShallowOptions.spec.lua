return function()
	local validateShallowOptions = require(script.Parent.validateShallowOptions)

	it("should return true given nil", function()
		expect(validateShallowOptions(nil)).to.equal(true)
	end)

	it("should return true given an empty table", function()
		expect(validateShallowOptions({})).to.equal(true)
	end)

	it("should return true if the key's value match the expected type", function()
		local success = validateShallowOptions({
			depth = 1,
		})

		expect(success).to.equal(true)
	end)

	it("should return false if a key is not expected", function()
		local success, message = validateShallowOptions({
			foo = 1,
		})

		expect(success).to.equal(false)
		expect(message).to.be.a("string")
	end)

	it("should return false if an expected value has not the correct type", function()
		local success, message = validateShallowOptions({
			depth = "foo",
		})

		expect(success).to.equal(false)
		expect(message).to.be.a("string")
	end)
end