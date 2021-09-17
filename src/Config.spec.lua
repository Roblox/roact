return function()
	local Config = require(script.Parent.Config)

	it("should accept valid configuration", function()
		local config = Config.new()
		local values = config.get()

		expect(values.elementTracing).to.equal(false)

		config.set({
			elementTracing = true,
		})

		expect(values.elementTracing).to.equal(true)
	end)

	it("should reject invalid configuration keys", function()
		local config = Config.new()

		local badKey = "garblegoop"

		local ok, err = pcall(function()
			config.set({
				[badKey] = true,
			})
		end)

		expect(ok).to.equal(false)

		-- The error should mention our bad key somewhere.
		expect(err:find(badKey)).to.be.ok()
	end)

	it("should reject invalid configuration values", function()
		local config = Config.new()

		local goodKey = "elementTracing"
		local badValue = "Hello there!"

		local ok, err = pcall(function()
			config.set({
				[goodKey] = badValue,
			})
		end)

		expect(ok).to.equal(false)

		-- The error should mention both our key and value
		expect(err:find(goodKey)).to.be.ok()
		expect(err:find(badValue)).to.be.ok()
	end)
end
