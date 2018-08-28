return function()
	local ChildUtils = require(script.Parent.ChildUtils)
	local createElement = require(script.Parent.createElement)
	local Type = require(script.Parent.Type)

	describe("iterateChildren", function()
		it("should iterate once for a single child", function()
			local child = createElement("TextLabel")
			local iterator = ChildUtils.iterateChildren(child)
			local iteratedKey, iteratedChild = iterator()
			-- For single elements, the key should be UseParentKey
			expect(iteratedKey).to.equal(ChildUtils.UseParentKey)
			expect(iteratedChild).to.equal(child)

			iteratedKey = iterator()
			expect(iteratedKey).to.equal(nil)
		end)

		it("should iterate over multiple children", function()
			local children = {
				a = createElement("TextLabel"),
				b = createElement("TextLabel"),
			}

			local seenChildren = {}
			local count = 0

			for key, child in ChildUtils.iterateChildren(children) do
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
			local booleanIterator = ChildUtils.iterateChildren(false)
			expect(booleanIterator()).to.equal(nil)
		end)

		it("should return a zero-element iterator for nil", function()
			local nilIterator = ChildUtils.iterateChildren(nil)
			expect(nilIterator()).to.equal(nil)
		end)

		it("should throw if given an illegal value", function()
			expect(function()
				ChildUtils.iterateChildren(1)
			end).to.throw()
		end)
	end)

	describe("getChildByKey", function()
		it("should return nil for booleans", function()
			expect(ChildUtils.getChildByKey(true, "test")).to.equal(nil)
		end)

		it("should return nil for nil", function()
			expect(ChildUtils.getChildByKey(nil, "test")).to.equal(nil)
		end)

		describe("single elements", function()
			local element = createElement("TextLabel")

			it("should return the element if the key is UseParentKey", function()
				expect(ChildUtils.getChildByKey(element, ChildUtils.UseParentKey)).to.equal(element)
			end)

			it("should return nil if the key is not UseParentKey", function()
				expect(ChildUtils.getChildByKey(element, "test")).to.equal(nil)
			end)
		end)

		it("should return the corresponding element", function()
			local children = {
				a = createElement("TextLabel"),
				b = createElement("TextLabel"),
			}

			expect(ChildUtils.getChildByKey(children, "a")).to.equal(children.a)
			expect(ChildUtils.getChildByKey(children, "b")).to.equal(children.b)
		end)

		it("should return nil if the key does not exist", function()
			local children = {}

			expect(ChildUtils.getChildByKey(children, "a")).to.equal(nil)
		end)
	end)
end