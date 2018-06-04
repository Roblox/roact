return function()
	local ReconcilerCompat = require(script.Parent.ReconcilerCompat)
	local Reconciler = require(script.Parent.Reconciler)
	local createElement = require(script.Parent.createElement)

	it("reify should only warn once per call site", function()
		local callCount = 0
		local lastMessage
		ReconcilerCompat._warn = function(message)
			callCount = callCount + 1
			lastMessage = message
		end

		-- We're using a loop so that we get the same stack trace and only one
		-- warning hopefully.
		for _ = 1, 2 do
			local handle = ReconcilerCompat.reify(createElement("StringValue"))
			Reconciler.unmount(handle)
		end

		expect(callCount).to.equal(1)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()

		-- This is a different call site, which should trigger another warning.
		local handle = ReconcilerCompat.reify(createElement("StringValue"))
		Reconciler.unmount(handle)

		expect(callCount).to.equal(2)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()

		ReconcilerCompat._warn = warn
	end)

	it("teardown should only warn once per call site", function()
		local callCount = 0
		local lastMessage
		ReconcilerCompat._warn = function(message)
			callCount = callCount + 1
			lastMessage = message
		end

		-- We're using a loop so that we get the same stack trace and only one
		-- warning hopefully.
		for _ = 1, 2 do
			local handle = Reconciler.mount(createElement("StringValue"))
			ReconcilerCompat.teardown(handle)
		end

		expect(callCount).to.equal(1)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()

		-- This is a different call site, which should trigger another warning.
		local handle = Reconciler.mount(createElement("StringValue"))
		ReconcilerCompat.teardown(handle)

		expect(callCount).to.equal(2)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()

		ReconcilerCompat._warn = warn
	end)
end