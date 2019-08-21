return function()
	local IndentedOutput = require(script.Parent.IndentedOutput)

	describe("join", function()
		it("should concat the lines with a new line by default", function()
			local output = IndentedOutput.new()

			output:write("foo")
			output:write("bar")

			expect(output:join()).to.equal("foo\nbar")
		end)

		it("should concat the lines with the given string", function()
			local output = IndentedOutput.new()

			output:write("foo")
			output:write("bar")

			expect(output:join("-")).to.equal("foo-bar")
		end)
	end)

	describe("write", function()
		it("should remove trailing whitespaces", function()
			local output = IndentedOutput.new()

			output:push()
			output:write("foo")
			output:write("")
			output:write("bar")

			expect(output:join()).to.equal("  foo\n\n  bar")
		end)
	end)

	describe("push", function()
		it("should indent next written lines", function()
			local output = IndentedOutput.new()

			output:write("foo")
			output:push()
			output:write("bar")

			expect(output:join()).to.equal("foo\n  bar")
		end)
	end)

	describe("pop", function()
		it("should dedent next written lines", function()
			local output = IndentedOutput.new()

			output:write("foo")
			output:push()
			output:write("bar")
			output:pop()
			output:write("baz")

			expect(output:join()).to.equal("foo\n  bar\nbaz")
		end)
	end)

	describe("writeAndPush", function()
		it("should write the line and push", function()
			local output = IndentedOutput.new()

			output:writeAndPush("foo")
			output:write("bar")

			expect(output:join()).to.equal("foo\n  bar")
		end)
	end)

	describe("popAndWrite", function()
		it("should pop and write the line", function()
			local output = IndentedOutput.new()

			output:writeAndPush("foo")
			output:write("bar")
			output:popAndWrite("baz")

			expect(output:join()).to.equal("foo\n  bar\nbaz")
		end)
	end)
end