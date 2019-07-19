return function()
	local assertDeepEqual = require(script.Parent.assertDeepEqual)

	it("should not throw if the args are equal", function()
		assertDeepEqual(1, 1)
		assertDeepEqual("hello", "hello")
	end)

	it("should throw and format the error message when args are not equal", function()
		local success, message = pcall(assertDeepEqual, 1, 2)

		expect(success).to.equal(false)
		expect(message:find("first ~= second")).to.be.ok()

		success, message = pcall(assertDeepEqual, {
			foo = 1,
		}, {
			foo = 2,
		})

		expect(success).to.equal(false)
		expect(message:find("first%[foo%] ~= second%[foo%]")).to.be.ok()
		expect(message:find("{1}")).never.to.be.ok()
		expect(message:find("{2}")).never.to.be.ok()
	end)
end