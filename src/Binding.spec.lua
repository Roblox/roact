return function()
	local createSpy = require(script.Parent.createSpy)
	local Type = require(script.Parent.Type)
	local GlobalConfig = require(script.Parent.GlobalConfig)

	local Binding = require(script.Parent.Binding)

	describe("Binding.create", function()
		it("should return a Binding object and an update function", function()
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

		it("should throw when updated directly", function()
			local source = Binding.create(1)
			local mapped = source:map(function(v)
				return v
			end)

			expect(function()
				Binding.update(mapped, 5)
			end).to.throw()
		end)
	end)

	describe("Binding.join", function()
		it("should have getValue", function()
			local binding1 = Binding.create(1)
			local binding2 = Binding.create(2)
			local binding3 = Binding.create(3)

			local joinedBinding = Binding.join({
				binding1,
				binding2,
				foo = binding3,
			})

			local bindingValue = joinedBinding:getValue()
			expect(bindingValue).to.be.a("table")
			expect(bindingValue[1]).to.equal(1)
			expect(bindingValue[2]).to.equal(2)
			expect(bindingValue.foo).to.equal(3)
		end)

		it("should update when any one of the subscribed bindings updates", function()
			local binding1, update1 = Binding.create(1)
			local binding2, update2 = Binding.create(2)
			local binding3, update3 = Binding.create(3)

			local joinedBinding = Binding.join({
				binding1,
				binding2,
				foo = binding3,
			})

			local spy = createSpy()
			Binding.subscribe(joinedBinding, spy.value)

			expect(spy.callCount).to.equal(0)

			update1(3)
			expect(spy.callCount).to.equal(1)

			local args = spy:captureValues("value")
			expect(args.value).to.be.a("table")
			expect(args.value[1]).to.equal(3)
			expect(args.value[2]).to.equal(2)
			expect(args.value["foo"]).to.equal(3)

			update2(4)
			expect(spy.callCount).to.equal(2)

			args = spy:captureValues("value")
			expect(args.value).to.be.a("table")
			expect(args.value[1]).to.equal(3)
			expect(args.value[2]).to.equal(4)
			expect(args.value["foo"]).to.equal(3)

			update3(8)
			expect(spy.callCount).to.equal(3)

			args = spy:captureValues("value")
			expect(args.value).to.be.a("table")
			expect(args.value[1]).to.equal(3)
			expect(args.value[2]).to.equal(4)
			expect(args.value["foo"]).to.equal(8)
		end)

		it("should disconnect from all upstream bindings", function()
			local binding1, update1 = Binding.create(1)
			local binding2, update2 = Binding.create(2)

			local joined = Binding.join({ binding1, binding2 })

			local spy = createSpy()
			local disconnect = Binding.subscribe(joined, spy.value)

			expect(spy.callCount).to.equal(0)

			update1(3)
			expect(spy.callCount).to.equal(1)

			update2(3)
			expect(spy.callCount).to.equal(2)

			disconnect()
			update1(4)
			expect(spy.callCount).to.equal(2)

			update2(2)
			expect(spy.callCount).to.equal(2)

			local value = joined:getValue()
			expect(value[1]).to.equal(4)
			expect(value[2]).to.equal(2)
		end)

		it("should be okay with calling disconnect multiple times", function()
			local joined = Binding.join({})

			local disconnect = Binding.subscribe(joined, function() end)

			disconnect()
			disconnect()
		end)

		it("should throw if updated directly", function()
			local joined = Binding.join({})

			expect(function()
				Binding.update(joined, 0)
			end)
		end)

		it("should throw when a non-table value is passed", function()
			GlobalConfig.scoped({
				typeChecks = true,
			}, function()
				expect(function()
					Binding.join("hi")
				end).to.throw()
			end)
		end)

		it("should throw when a non-binding value is passed via table", function()
			GlobalConfig.scoped({
				typeChecks = true,
			}, function()
				expect(function()
					local binding = Binding.create(123)

					Binding.join({
						binding,
						"abcde",
					})
				end).to.throw()
			end)
		end)
	end)
end
