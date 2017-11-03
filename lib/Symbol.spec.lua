return function()
	local Symbol = require(script.Parent.Symbol)

	describe("named", function()
		it("should give an opaque object", function()
			local symbol = Symbol.named("foo")

			expect(symbol).to.be.a("userdata")
		end)

		it("should coerce to the given name", function()
			local symbol = Symbol.named("foo")

			expect(tostring(symbol):find("foo")).to.be.ok()
		end)

		it("should be unique when constructed", function()
			local symbolA = Symbol.named("abc")
			local symbolB = Symbol.named("abc")

			expect(symbolA).never.to.equal(symbolB)
		end)
	end)

	describe("unnamed", function()
		it("should give an opaque object", function()
			local symbol = Symbol.unnamed()

			expect(symbol).to.be.a("userdata")
		end)

		it("should coerce to some string", function()
			local symbol = Symbol.unnamed()

			expect(tostring(symbol)).to.be.a("string")
		end)

		it("should be unique when constructed", function()
			local symbolA = Symbol.unnamed()
			local symbolB = Symbol.unnamed()

			expect(symbolA).never.to.equal(symbolB)
		end)
	end)
end