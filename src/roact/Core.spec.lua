return function()
	local Core = require(script.Parent.Core)

	describe("createElement", function()
		it("should create new primitive elements", function()
			local element = Core.createElement("Frame")

			expect(element).to.be.ok()

			expect(Core.isPrimitiveElement(element)).to.equal(true)
		end)

		it("should create new functional elements", function()
			local element = Core.createElement(function()
			end)

			expect(element).to.be.ok()

			expect(Core.isFunctionalElement(element)).to.equal(true)
		end)

		it("should create new stateful components", function()
			local element = Core.createElement({})

			expect(element).to.be.ok()

			expect(Core.isStatefulElement(element)).to.equal(true)
		end)
	end)

	describe("oneChild", function()
		it("should get zero children from a table", function()
			local children = {}

			expect(Core.oneChild(children)).to.equal(nil)
		end)

		it("should get exactly one child", function()
			local child = Core.createElement("Frame")
			local children = {
				foo = child,
			}

			expect(Core.oneChild(children)).to.equal(child)
		end)

		it("should error with more than one child", function()
			local children = {
				a = Core.createElement("Frame"),
				b = Core.createElement("Frame"),
			}

			expect(function()
				Core.oneChild(children)
			end).to.throw()
		end)

		it("should handle being passed nil", function()
			expect(Core.oneChild(nil)).to.equal(nil)
		end)
	end)

	describe("Event", function()
		it("should yield event objects when indexed", function()
			expect(Core.Event.MouseButton1Click).to.be.ok()
			expect(Core.Event.Touched).to.be.ok()
		end)
	end)
end