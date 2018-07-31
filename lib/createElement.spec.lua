return function()
	local Component = require(script.Parent.Component)

	local createElement = require(script.Parent.createElement)

	it("should create new primitive elements", function()
		local element = createElement("Frame")

		expect(element).to.be.ok()
	end)

	it("should create new functional elements", function()
		local element = createElement(function()
		end)

		expect(element).to.be.ok()
	end)

	it("should create new stateful components", function()
		local Foo = Component:extend("Foo")

		local element = createElement(Foo)

		expect(element).to.be.ok()
	end)

	it("should accept props", function()
		local element = createElement("StringValue", {
			Value = "Foo",
		})

		expect(element).to.be.ok()
	end)

	it("should accept props and children", function()
		local element = createElement("StringValue", {
			Value = "Foo",
		}, {
			Child = createElement("IntValue", {
				Value = 6,
			}),
		})

		expect(element).to.be.ok()
	end)
end