return function()
	local Binding = require(script.Parent.Binding)

	describe("Binding.create", function()
		it("should also return an update function", function()
			local _, update = Binding.create(0)

			expect(update).to.be.ok()
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

			local lastUpdateValue = nil

			local disconnect = Binding.subscribe(binding, function(value)
				lastUpdateValue = value
			end)

			expect(lastUpdateValue).to.equal(nil)
			expect(binding:getValue()).to.equal(1)

			update(2)

			expect(lastUpdateValue).to.equal(2)
			expect(binding:getValue()).to.equal(2)

			disconnect()
			update(3)

			expect(lastUpdateValue).to.equal(2)
			expect(binding:getValue()).to.equal(3)
		end)
	end)

	describe("Mapped bindings", function()
		it("should be composable", function()
			local word, updateWord = Binding.create("hi")

			local length = word:map(function(value)
				return string.len(value)
			end)

			local isEvenLength = length:map(function(value)
				return value % 2 == 0
			end)

			expect(word:getValue()).to.equal("hi")
			expect(length:getValue()).to.equal(2)
			expect(isEvenLength:getValue()).to.equal(true)

			updateWord("sup")

			expect(word:getValue()).to.equal("sup")
			expect(length:getValue()).to.equal(3)
			expect(isEvenLength:getValue()).to.equal(false)
		end)

		it("should cascade updates when subscribed", function()
			-- base binding
			local word, updateWord = Binding.create("hi")

			local lastWord = nil
			local disconnectWord = Binding.subscribe(word, function(value)
				lastWord = value
			end)

			-- binding -> base binding
			local length = word:map(function(value)
				return string.len(value)
			end)

			local lastLength = nil
			local disconnectLength = Binding.subscribe(length, function(value)
				lastLength = value
			end)

			-- binding -> binding -> base binding
			local isEvenLength = length:map(function(value)
				return value % 2 == 0
			end)

			local lastEvenLength = nil
			local disconnectIsEvenLength = Binding.subscribe(isEvenLength, function(value)
				lastEvenLength = value
			end)

			expect(lastWord).never.to.be.ok()
			expect(lastLength).never.to.be.ok()
			expect(lastEvenLength).never.to.be.ok()

			updateWord("nice")

			expect(lastWord).to.equal("nice")
			expect(lastLength).to.equal(4)
			expect(lastEvenLength).to.equal(true)

			disconnectWord()
			disconnectLength()
			disconnectIsEvenLength()

			updateWord("goodbye")

			expect(lastWord).to.equal("nice")
			expect(lastLength).to.equal(4)
			expect(lastEvenLength).to.equal(true)
		end)
	end)
end
