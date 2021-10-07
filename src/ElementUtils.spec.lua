return function()
	local ElementUtils = require(script.Parent.ElementUtils)
	local createElement = require(script.Parent.createElement)
	local createFragment = require(script.Parent.createFragment)
	local Type = require(script.Parent.Type)

	describe("iterateElements", function()
		it("should iterate once for a single child", function()
			local child = createElement("TextLabel")
			local iterator = ElementUtils.iterateElements(child)
			local iteratedKey, iteratedChild = iterator()
			-- For single elements, the key should be UseParentKey
			expect(iteratedKey).to.equal(ElementUtils.UseParentKey)
			expect(iteratedChild).to.equal(child)

			iteratedKey = iterator()
			expect(iteratedKey).to.equal(nil)
		end)

		it("should iterate over tables", function()
			local children = {
				a = createElement("TextLabel"),
				b = createElement("TextLabel"),
			}

			local seenChildren = {}
			local count = 0

			for key, child in ElementUtils.iterateElements(children) do
				expect(typeof(key)).to.equal("string")
				expect(Type.of(child)).to.equal(Type.Element)
				seenChildren[child] = key
				count = count + 1
			end

			expect(count).to.equal(2)
			expect(seenChildren[children.a]).to.equal("a")
			expect(seenChildren[children.b]).to.equal("b")
		end)

		it("should return a zero-element iterator for booleans", function()
			local booleanIterator = ElementUtils.iterateElements(false)
			expect(booleanIterator()).to.equal(nil)
		end)

		it("should return a zero-element iterator for nil", function()
			local nilIterator = ElementUtils.iterateElements(nil)
			expect(nilIterator()).to.equal(nil)
		end)

		it("should throw if given an illegal value", function()
			expect(function()
				ElementUtils.iterateElements(1)
			end).to.throw()
		end)
	end)

	describe("getElementByKey", function()
		it("should return nil for booleans", function()
			expect(ElementUtils.getElementByKey(true, "test")).to.equal(nil)
		end)

		it("should return nil for nil", function()
			expect(ElementUtils.getElementByKey(nil, "test")).to.equal(nil)
		end)

		describe("single elements", function()
			local element = createElement("TextLabel")

			it("should return the element if the key is UseParentKey", function()
				expect(ElementUtils.getElementByKey(element, ElementUtils.UseParentKey)).to.equal(element)
			end)

			it("should return nil if the key is not UseParentKey", function()
				expect(ElementUtils.getElementByKey(element, "test")).to.equal(nil)
			end)
		end)

		it("should return the corresponding element from a table", function()
			local children = {
				a = createElement("TextLabel"),
				b = createElement("TextLabel"),
			}

			expect(ElementUtils.getElementByKey(children, "a")).to.equal(children.a)
			expect(ElementUtils.getElementByKey(children, "b")).to.equal(children.b)
		end)

		it("should return nil if the key does not exist", function()
			local children = createFragment({})

			expect(ElementUtils.getElementByKey(children, "a")).to.equal(nil)
		end)
	end)
end
