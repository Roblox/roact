return function()
	local None = require(script.Parent.None)

	local assign = require(script.Parent.assign)

	it("should accept zero additional tables", function()
		local input = {}
		local result = assign(input)

		expect(input).to.equal(result)
	end)

	it("should merge multiple tables onto the given target table", function()
		local target: { a: number, b: number, c: number? } = {
			a = 5,
			b = 6,
		}

		local source1 = {
			b = 7,
			c = 8,
		}

		local source2 = {
			b = 8,
		}

		assign(target, source1, source2)

		expect(target.a).to.equal(5)
		expect(target.b).to.equal(source2.b)
		expect(target.c).to.equal(source1.c)
	end)

	it("should remove keys if specified as None", function()
		local target = {
			foo = 2,
			bar = 3,
		}

		local source = {
			foo = None,
		}

		assign(target, source)

		expect(target.foo).to.equal(nil)
		expect(target.bar).to.equal(3)
	end)

	it("should re-add keys if specified after None", function()
		local target = {
			foo = 2,
		}

		local source1 = {
			foo = None,
		}

		local source2 = {
			foo = 3,
		}

		assign(target, source1, source2)

		expect(target.foo).to.equal(source2.foo)
	end)
end
