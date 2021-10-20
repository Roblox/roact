return function()
	local GlobalConfig = require(script.Parent.GlobalConfig)

	it("should have the correct methods", function()
		expect(GlobalConfig).to.be.ok()
		expect(GlobalConfig.set).to.be.ok()
		expect(GlobalConfig.get).to.be.ok()
	end)
end
