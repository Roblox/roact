return function()
	local createSpy = require(script.Parent.createSpy)
	local Type = require(script.Parent.Type)

	local Binding = require(script.Parent.Binding)

	describe("Binding.create", function()
		it("should return object with Type `Binding`", function()
			local binding, update = Binding.create(1)

			expect(Type.of(binding)).to.equal(Type.Binding)
			expect(typeof(update)).to.equal("function")
		end)

		it("should support tostring on bindings", function()
			local binding, update = Binding.create(1)
			expect(tostring(binding)).to.equal("RoactBinding(1)")

			update("foo")
			expect(tostring(binding)).to.equal("RoactBinding(foo)")
		end)
	end)

	describe("Binding object", function()
		it("should provide a getter and setter", function()
			local binding, update = Binding.create(1)

			expect(binding:getValue()).to.equal(1)

			update(3)

			expect(binding:getValue()).to.equal(3)
		end)

		it("should let users subscribe and unsubscribe to its updates", function()
			local binding, update = Binding.create(1)

			local spy = createSpy()
			local disconnect = Binding.subscribe(binding, spy.value)

			expect(spy.callCount).to.equal(0)

			update(2)

			expect(spy.callCount).to.equal(1)
			spy:assertCalledWith(2)

			disconnect()
			update(3)

			expect(spy.callCount).to.equal(1)
		end)
	end)

	describe("Mapped bindings", function()
		it("should be composable", function()
			local word, updateWord = Binding.create("hi")

			local wordLength = word:map(string.len)
			local isEvenLength = wordLength:map(function(value)
				return value % 2 == 0
			end)

			expect(word:getValue()).to.equal("hi")
			expect(wordLength:getValue()).to.equal(2)
			expect(isEvenLength:getValue()).to.equal(true)

			updateWord("sup")

			expect(word:getValue()).to.equal("sup")
			expect(wordLength:getValue()).to.equal(3)
			expect(isEvenLength:getValue()).to.equal(false)
		end)

		it("should cascade updates when subscribed", function()
			-- base binding
			local word, updateWord = Binding.create("hi")

			local wordSpy = createSpy()
			local disconnectWord = Binding.subscribe(word, wordSpy.value)

			-- binding -> base binding
			local length = word:map(string.len)

			local lengthSpy = createSpy()
			local disconnectLength = Binding.subscribe(length, lengthSpy.value)

			-- binding -> binding -> base binding
			local isEvenLength = length:map(function(value)
				return value % 2 == 0
			end)

			local isEvenLengthSpy = createSpy()
			local disconnectIsEvenLength = Binding.subscribe(isEvenLength, isEvenLengthSpy.value)

			expect(wordSpy.callCount).to.equal(0)
			expect(lengthSpy.callCount).to.equal(0)
			expect(isEvenLengthSpy.callCount).to.equal(0)

			updateWord("nice")

			expect(wordSpy.callCount).to.equal(1)
			wordSpy:assertCalledWith("nice")

			expect(lengthSpy.callCount).to.equal(1)
			lengthSpy:assertCalledWith(4)

			expect(isEvenLengthSpy.callCount).to.equal(1)
			isEvenLengthSpy:assertCalledWith(true)

			disconnectWord()
			disconnectLength()
			disconnectIsEvenLength()

			updateWord("goodbye")

			expect(wordSpy.callCount).to.equal(1)
			expect(isEvenLengthSpy.callCount).to.equal(1)
			expect(lengthSpy.callCount).to.equal(1)
		end)
	end)
end
