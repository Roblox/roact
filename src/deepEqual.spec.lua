return function()
	local deepEqual = require(script.Parent.deepEqual)

	it("should compare non-table values using standard '==' equality", function()
		expect(deepEqual(1, 1)).to.equal(true)
		expect(deepEqual("hello", "hello")).to.equal(true)
		expect(deepEqual(nil, nil)).to.equal(true)

		local someFunction = function() end
		local theSameFunction = someFunction

		expect(deepEqual(someFunction, theSameFunction)).to.equal(true)

		local A = {
			foo = someFunction
		}
		local B = {
			foo = theSameFunction
		}

		expect(deepEqual(A, B)).to.equal(true)
	end)

	it("should fail with a message when args are not equal", function()
		local success, message = deepEqual(1, 2)

		expect(success).to.equal(false)
		expect(message:find("{1} ~= {2}")).to.be.ok()

		success, message = deepEqual({
			foo = 1,
		}, {
			foo = 2,
		})

		expect(success).to.equal(false)
		expect(message:find("{1}%[foo%] ~= {2}%[foo%]")).to.be.ok()
	end)

	it("should fail when types differ", function()
		local success, message = deepEqual(1, "1")

		expect(success).to.equal(false)
		expect(message:find("{1} is of type number, but {2} is of type string")).to.be.ok()
	end)

	it("should compare (and report about) nested tables", function()
		local A = {
			foo = "bar",
			nested = {
				foo = 1,
				bar = 2,
			}
		}
		local B = {
			foo = "bar",
			nested = {
				foo = 1,
				bar = 2,
			}
		}

		deepEqual(A, B)

		local C = {
			foo = "bar",
			nested = {
				foo = 1,
				bar = 3,
			}
		}

		local success, message = deepEqual(A, C)

		expect(success).to.equal(false)
		expect(message:find("{1}%[nested%]%[bar%] ~= {2}%[nested%]%[bar%]")).to.be.ok()
	end)

	it("should be commutative", function()
		local equalArgsA = {
			foo = "bar",
			hello = "world",
		}
		local equalArgsB = {
			foo = "bar",
			hello = "world",
		}

		expect(deepEqual(equalArgsA, equalArgsB)).to.equal(true)
		expect(deepEqual(equalArgsB, equalArgsA)).to.equal(true)

		local nonEqualArgs = {
			foo = "bar",
		}

		expect(deepEqual(equalArgsA, nonEqualArgs)).to.equal(false)
		expect(deepEqual(nonEqualArgs, equalArgsA)).to.equal(false)
	end)
end