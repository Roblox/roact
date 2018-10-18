return function()
	local Type = require(script.Parent.Type)

	local Binding = require(script.Parent.Binding)
FOCUS()
	describe("Binding.create", function()

		it("should return object with Type 'Binding'", function()
			local binding = Binding.create(1)

			expect(Type.of(binding)).to.equal(Type.Binding)
		end)

		it("should also return an update function", function()
			local _, update = Binding.create(0)

			expect(update).to.be.ok()
			expect(typeof(update)).to.equal("function")
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

			local disconnect = binding:subscribe(function(value)
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
			local a, update = Binding.create("hi")

			local length = a:map(function(value)
				return string.len(value)
			end)

			local isEvenLength = length:map(function(value)
				return value % 2 == 0
			end)

			expect(a:getValue()).to.equal("hi")
			expect(length:getValue()).to.equal(2)
			expect(isEvenLength:getValue()).to.equal(true)

			update("sup")

			expect(a:getValue()).to.equal("sup")
			expect(length:getValue()).to.equal(3)
			expect(isEvenLength:getValue()).to.equal(false)
		end)
	end)
end