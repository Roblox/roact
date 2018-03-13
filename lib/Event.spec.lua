return function()
	local Event = require(script.Parent.Event)

	it("should yield event objects when indexed", function()
		expect(Event.MouseButton1Click).to.be.ok()
		expect(Event.Touched).to.be.ok()
	end)

	it("should yield the same object when indexed again", function()
		local a = Event.MouseButton1Click
		local b = Event.MouseButton1Click

		expect(a).to.equal(b)
	end)
end