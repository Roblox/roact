return function()
	local Type = require(script.Parent.Parent.Type)

	local Event = require(script.Parent.Event)

	it("should yield event objects when indexed", function()
		expect(Type.of(Event.MouseButton1Click)).to.equal(Type.HostEvent)
		expect(Type.of(Event.Touched)).to.equal(Type.HostEvent)
	end)

	it("should yield the same object when indexed again", function()
		local a = Event.MouseButton1Click
		local b = Event.MouseButton1Click
		local c = Event.Touched

		expect(a).to.equal(b)
		expect(a).never.to.equal(c)
	end)
end
