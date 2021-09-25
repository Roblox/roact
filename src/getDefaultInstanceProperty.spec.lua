return function()
	local getDefaultInstanceProperty = require(script.Parent.getDefaultInstanceProperty)

	it("should get default name string values", function()
		local _, defaultName = getDefaultInstanceProperty("StringValue", "Name")

		expect(defaultName).to.equal("Value")
	end)

	it("should get default empty string values", function()
		local _, defaultValue = getDefaultInstanceProperty("StringValue", "Value")

		expect(defaultValue).to.equal("")
	end)

	it("should get default number values", function()
		local _, defaultValue = getDefaultInstanceProperty("IntValue", "Value")

		expect(defaultValue).to.equal(0)
	end)

	it("should get nil default values", function()
		local _, defaultValue = getDefaultInstanceProperty("ObjectValue", "Value")

		expect(defaultValue).to.equal(nil)
	end)

	it("should get bool default values", function()
		local _, defaultValue = getDefaultInstanceProperty("BoolValue", "Value")

		expect(defaultValue).to.equal(false)
	end)
end
