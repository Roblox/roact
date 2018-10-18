return function()
	local Type = require(script.Parent.Type)

	local createRef = require(script.Parent.createRef)

	it("should create refs, which are specialized bindings", function()
		local ref = createRef()
		expect(Type.of(ref)).to.equal(Type.Binding)
		expect(ref.current).to.equal(nil)
	end)
end