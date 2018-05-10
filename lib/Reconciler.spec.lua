return function()
	local Reconciler = require(script.Parent.Reconciler)

	it("should mount booleans as nil", function()
		local booleanReified = Reconciler.mount(false)
		expect(booleanReified).to.never.be.ok()
	end)
end