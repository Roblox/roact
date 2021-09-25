return function()
	local Portal = require(script.Parent.Portal)
	local Component = require(script.Parent.Component)

	local ElementKind = require(script.Parent.ElementKind)

	describe("of", function()
		it("should return nil for non-table values", function()
			expect(ElementKind.of(nil)).to.equal(nil)
			expect(ElementKind.of(5)).to.equal(nil)
			expect(ElementKind.of(newproxy(true))).to.equal(nil)
		end)

		it("should return nil for table values without an ElementKind key", function()
			expect(ElementKind.of({})).to.equal(nil)
		end)

		it("should return the ElementKind from a table", function()
			local value = {
				[ElementKind] = ElementKind.Stateful,
			}

			expect(ElementKind.of(value)).to.equal(ElementKind.Stateful)
		end)
	end)

	describe("fromComponent", function()
		it("should handle host components", function()
			expect(ElementKind.fromComponent("foo")).to.equal(ElementKind.Host)
		end)

		it("should handle function components", function()
			local function foo() end

			expect(ElementKind.fromComponent(foo)).to.equal(ElementKind.Function)
		end)

		it("should handle stateful components", function()
			local Foo = Component:extend("Foo")

			expect(ElementKind.fromComponent(Foo)).to.equal(ElementKind.Stateful)
		end)

		it("should handle portals", function()
			expect(ElementKind.fromComponent(Portal)).to.equal(ElementKind.Portal)
		end)

		it("should return nil for invalid inputs", function()
			expect(ElementKind.fromComponent(5)).to.equal(nil)
			expect(ElementKind.fromComponent(newproxy(true))).to.equal(nil)
		end)
	end)
end
