return function()
	local createRef = require(script.Parent.createRef)

	it("should create refs", function()
		expect(createRef()).to.be.ok()
	end)
end