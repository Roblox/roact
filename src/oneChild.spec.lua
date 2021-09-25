return function()
	local createElement = require(script.Parent.createElement)

	local oneChild = require(script.Parent.oneChild)

	it("should get zero children from a table", function()
		local children = {}

		expect(oneChild(children)).to.equal(nil)
	end)

	it("should get exactly one child", function()
		local child = createElement("Frame")
		local children = {
			foo = child,
		}

		expect(oneChild(children)).to.equal(child)
	end)

	it("should error with more than one child", function()
		local children = {
			a = createElement("Frame"),
			b = createElement("Frame"),
		}

		expect(function()
			oneChild(children)
		end).to.throw()
	end)

	it("should handle being passed nil", function()
		expect(oneChild(nil)).to.equal(nil)
	end)
end
