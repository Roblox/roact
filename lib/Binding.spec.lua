return function()
	local Binding = require(script.Parent.Binding)

	describe("Binding.create", function()
		it("should support tostring on bindings", function()
			local binding = Binding.create(1)
			expect(tostring(binding)).to.equal("RoactBinding(1)")

			Binding.update(binding, "foo")
			expect(tostring(binding)).to.equal("RoactBinding(foo)")
		end)
	end)

	describe("Binding object", function()
		it("should provide a getter and setter", function()
			local binding = Binding.create(1)

			expect(binding:getValue()).to.equal(1)

			Binding.update(binding, 3)

			expect(binding:getValue()).to.equal(3)
		end)

		it("should let users subscribe and unsubscribe to its updates", function()
			local binding = Binding.create(1)

			local lastUpdateValue = nil

			local disconnect = Binding.subscribe(binding, function(value)
				lastUpdateValue = value
			end)

			expect(lastUpdateValue).to.equal(nil)
			expect(binding:getValue()).to.equal(1)

			Binding.update(binding, 2)

			expect(lastUpdateValue).to.equal(2)
			expect(binding:getValue()).to.equal(2)

			disconnect()
			Binding.update(binding, 3)

			expect(lastUpdateValue).to.equal(2)
			expect(binding:getValue()).to.equal(3)
		end)
	end)
end
