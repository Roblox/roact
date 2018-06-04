return function()
	local createRef = require(script.Parent.createRef)

	it("should create refs", function()
		expect(createRef()).to.be.ok()
	end)

	it("should support tostring on refs", function()
		local ref = createRef()
		expect(tostring(ref)).to.equal("RoactReference(nil)")

		ref.current = "foo"
		expect(tostring(ref)).to.equal("RoactReference(foo)")
	end)
end