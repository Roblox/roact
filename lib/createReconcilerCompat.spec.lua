return function()
	local createReconcilerCompat = require(script.Parent.createReconcilerCompat)
	local createReconciler = require(script.Parent.createReconciler)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local createElement = require(script.Parent.createElement)

	local noopReconciler = createReconciler(NoopRenderer)

	it("reify should only warn once per call site", function()
		local callCount = 0
		local lastMessage

		local compat = createReconcilerCompat(noopReconciler, function(message)
			callCount = callCount + 1
			lastMessage = message
		end)

		-- We're using a loop so that we get the same stack trace and only one
		-- warning hopefully.
		for _ = 1, 2 do
			local handle = compat.reify(createElement("StringValue"))
			noopReconciler.unmountTree(handle)
		end

		expect(callCount).to.equal(1)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()

		-- This is a different call site, which should trigger another warning.
		local handle = compat.reify(createElement("StringValue"))
		noopReconciler.unmountTree(handle)

		expect(callCount).to.equal(2)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()
	end)

	it("teardown should only warn once per call site", function()
		local callCount = 0
		local lastMessage

		local compat = createReconcilerCompat(noopReconciler, function(message)
			callCount = callCount + 1
			lastMessage = message
		end)

		-- We're using a loop so that we get the same stack trace and only one
		-- warning hopefully.
		for _ = 1, 2 do
			local handle = noopReconciler.mountTree(createElement("StringValue"))
			compat.teardown(handle)
		end

		expect(callCount).to.equal(1)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()

		-- This is a different call site, which should trigger another warning.
		local handle = noopReconciler.mountTree(createElement("StringValue"))
		compat.teardown(handle)

		expect(callCount).to.equal(2)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()
	end)

	it("update should only warn once per call site", function()
		local callCount = 0
		local lastMessage

		local compat = createReconcilerCompat(noopReconciler, function(message)
			callCount = callCount + 1
			lastMessage = message
		end)

		for _ = 1, 2 do
			local handle = noopReconciler.mountTree(createElement("StringValue"))
			compat.reconcile(handle, createElement("StringValue"))
			noopReconciler.unmountTree(handle)
		end

		expect(callCount).to.equal(1)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()

		local handle = noopReconciler.mountTree(createElement("StringValue"))
		compat.reconcile(handle, createElement("StringValue"))
		noopReconciler.unmountTree(handle)

		expect(callCount).to.equal(2)
		expect(lastMessage:find("ReconcilerCompat.spec")).to.be.ok()
	end)
end