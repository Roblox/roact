return function()
	local Binding = require(script.Parent.Binding)
	local Type = require(script.Parent.Type)

	local createRef = require(script.Parent.createRef)

	it("should create refs, which are specialized bindings", function()
		local ref = createRef()

		expect(Type.of(ref)).to.equal(Type.Binding)
		expect(ref.current).to.equal(nil)
	end)

	it("should have a 'current' field that is the same as the internal binding's value", function()
		local ref = createRef()

		expect(ref.current).to.equal(nil)

		Binding.update(ref, 10)
		expect(ref.current).to.equal(10)
	end)

	it("should support tostring on refs", function()
		local ref = createRef()

		expect(ref.current).to.equal(nil)
		expect(tostring(ref)).to.equal("RoactRef(nil)")

		Binding.update(ref, 10)
		expect(tostring(ref)).to.equal("RoactRef(10)")
	end)

	it("should not allow assignments to the 'current' field", function()
		local ref = createRef()

		expect(ref.current).to.equal(nil)

		Binding.update(ref, 99)
		expect(ref.current).to.equal(99)

		expect(function()
			ref.current = 77
		end).to.throw()

		expect(ref.current).to.equal(99)
	end)

	it("should return the same thing from getValue as its current field", function()
		local ref = createRef()
		Binding.update(ref, 10)

		expect(ref:getValue()).to.equal(10)
		expect(ref:getValue()).to.equal(ref.current)
	end)
end
