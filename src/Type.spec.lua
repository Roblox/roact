return function()
	local Type = require(script.Parent.Type)

	describe("of", function()
		it("should return nil if the value is not a table", function()
			expect(Type.of(1)).to.equal(nil)
			expect(Type.of(true)).to.equal(nil)
			expect(Type.of("test")).to.equal(nil)
			expect(Type.of(print)).to.equal(nil)
		end)

		it("should return nil if the table has no type", function()
			expect(Type.of({})).to.equal(nil)
		end)

		it("should return the assigned type", function()
			local test = {
				[Type] = Type.Element,
			}

			expect(Type.of(test)).to.equal(Type.Element)
		end)
	end)
end
