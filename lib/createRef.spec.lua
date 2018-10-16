return function()
	local Type = require(script.Parent.Type)

	local createRef = require(script.Parent.createRef)

	it("should create refs", function()
		local ref = createRef()
		expect(Type.of(ref)).to.equal(Type.Ref)
		expect(ref.current).to.equal(nil)
	end)

	it("should support tostring on refs", function()
		local ref = createRef()
		expect(tostring(ref)).to.equal("RoactRef(nil)")

		ref.current = "foo"
		expect(tostring(ref)).to.equal("RoactRef(foo)")
	end)
end