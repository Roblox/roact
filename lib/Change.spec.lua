return function()
	local Change = require(script.Parent.Change)

	it("should yield change listener objects when indexed", function()
		expect(Change.Text).to.be.ok()
		expect(Change.Selected).to.be.ok()
	end)

	it("should yield the same object when indexed again", function()
		local a = Change.Text
		local b = Change.Text

		expect(a).to.equal(b)
	end)
end