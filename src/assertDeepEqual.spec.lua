return function()
	local assertDeepEqual = require(script.Parent.assertDeepEqual)

	it("should fail with a message when args are not equal", function()
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
	end)

	it("should compare non-table values using standard '==' equality", function()
		assertDeepEqual(1, 1)
		assertDeepEqual("hello", "hello")
		assertDeepEqual(nil, nil)

		local someFunction = function() end
		local theSameFunction = someFunction

		assertDeepEqual(someFunction, theSameFunction)

		local A = {
			foo = someFunction,
		}
		local B = {
			foo = theSameFunction,
		}

		assertDeepEqual(A, B)
	end)

	it("should fail when types differ", function()
		local success, message = pcall(assertDeepEqual, 1, "1")

		expect(success).to.equal(false)
		expect(message:find("first is of type number, but second is of type string")).to.be.ok()
	end)

	it("should compare (and report about) nested tables", function()
		local A = {
			foo = "bar",
			nested = {
				foo = 1,
				bar = 2,
			},
		}
		local B = {
			foo = "bar",
			nested = {
				foo = 1,
				bar = 2,
			},
		}

		assertDeepEqual(A, B)

		local C = {
			foo = "bar",
			nested = {
				foo = 1,
				bar = 3,
			},
		}

		local success, message = pcall(assertDeepEqual, A, C)

		expect(success).to.equal(false)
		expect(message:find("first%[nested%]%[bar%] ~= second%[nested%]%[bar%]")).to.be.ok()
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

		assertDeepEqual(equalArgsA, equalArgsB)
		assertDeepEqual(equalArgsB, equalArgsA)

		local nonEqualArgs = {
			foo = "bar",
		}

		expect(function()
			assertDeepEqual(equalArgsA, nonEqualArgs)
		end).to.throw()
		expect(function()
			assertDeepEqual(nonEqualArgs, equalArgsA)
		end).to.throw()
	end)
end
