return function()
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local Logging = require(script.Parent.Logging)
	local NoopRenderer = require(script.Parent.NoopRenderer)

	local createReconcilerCompat = require(script.Parent.createReconcilerCompat)

	local noopReconciler = createReconciler(NoopRenderer)
	local compatReconciler = createReconcilerCompat(noopReconciler)

	it("reify should only warn once per call site", function()
		local logInfo = Logging.capture(function()
			-- We're using a loop so that we get the same stack trace and only one
			-- warning hopefully.
			for _ = 1, 2 do
				local handle = compatReconciler.reify(createElement("StringValue"))
				noopReconciler.unmountVirtualTree(handle)
			end
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("reify")).to.be.ok()

		logInfo = Logging.capture(function()
			-- This is a different call site, which should trigger another warning.
			local handle = compatReconciler.reify(createElement("StringValue"))
			noopReconciler.unmountVirtualTree(handle)
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("reify")).to.be.ok()
	end)

	it("teardown should only warn once per call site", function()
		local logInfo = Logging.capture(function()
			-- We're using a loop so that we get the same stack trace and only one
			-- warning hopefully.
			for _ = 1, 2 do
				local handle = noopReconciler.mountVirtualTree(createElement("StringValue"))
				compatReconciler.teardown(handle)
			end
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("teardown")).to.be.ok()

		logInfo = Logging.capture(function()
			-- This is a different call site, which should trigger another warning.
			local handle = noopReconciler.mountVirtualTree(createElement("StringValue"))
			compatReconciler.teardown(handle)
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("teardown")).to.be.ok()
	end)

	it("update should only warn once per call site", function()
		local logInfo = Logging.capture(function()
			-- We're using a loop so that we get the same stack trace and only one
			-- warning hopefully.
			for _ = 1, 2 do
				local handle = noopReconciler.mountVirtualTree(createElement("StringValue"))
				compatReconciler.reconcile(handle, createElement("StringValue"))
				noopReconciler.unmountVirtualTree(handle)
			end
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("reconcile")).to.be.ok()

		logInfo = Logging.capture(function()
			-- This is a different call site, which should trigger another warning.
			local handle = noopReconciler.mountVirtualTree(createElement("StringValue"))
			compatReconciler.reconcile(handle, createElement("StringValue"))
			noopReconciler.unmountVirtualTree(handle)
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("reconcile")).to.be.ok()
	end)
end
