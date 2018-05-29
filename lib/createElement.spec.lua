return function()
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
		local element = createElement({})

		expect(element).to.be.ok()
	end)
end