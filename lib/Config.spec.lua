return function()
	local Config = require(script.Parent.Config)

	it("should accept valid configuration", function()
		local config = Config.new()

		expect(config.getValue("elementTracing")).to.equal(false)

		config.set({
			elementTracing = true,
		})

		expect(config.getValue("elementTracing")).to.equal(true)
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

	it("should prevent setting configuration more than once", function()
		local config = Config.new()

		-- We're going to use the name of this function to see if the traceback
		-- was correct.
		local function setEmptyConfig()
			config.set({})
		end

		setEmptyConfig()

		local ok, err = pcall(setEmptyConfig)

		expect(ok).to.equal(false)

		-- The error should mention the stack trace with the original set call.
		expect(err:find("setEmptyConfig")).to.be.ok()
	end)

	it("should reset to default values after invoking reset()", function()
		local config = Config.new()

		expect(config.getValue("elementTracing")).to.equal(false)

		config.set({
			elementTracing = true,
		})

		expect(config.getValue("elementTracing")).to.equal(true)

		config.reset()

		expect(config.getValue("elementTracing")).to.equal(false)
	end)
end