return function()
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local Logging = require(script.Parent.Logging)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local VirtualTree = require(script.Parent.VirtualTree)

	local createReconcilerCompat = require(script.Parent.createReconcilerCompat)

	local noopReconciler = createReconciler(NoopRenderer)

	local function mountWithNoop(element, hostParent, hostKey)
		return VirtualTree.mountWithOptions(element, {
			hostParent = hostParent,
			hostKey = hostKey,
			reconciler = noopReconciler
		})
	end

	local compatReconciler = createReconcilerCompat({
		mount = mountWithNoop,
		unmount = VirtualTree.unmount,
		update = VirtualTree.update,
	})

	it("reify should only warn once per call site", function()
		local logInfo = Logging.capture(function()
			-- We're using a loop so that we get the same stack trace and only one
			-- warning hopefully.
			for _ = 1, 2 do
				local handle = compatReconciler.reify(createElement("StringValue"))
				VirtualTree.unmount(handle)
			end
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("reify")).to.be.ok()

		logInfo = Logging.capture(function()
			-- This is a different call site, which should trigger another warning.
			local handle = compatReconciler.reify(createElement("StringValue"))
			VirtualTree.unmount(handle)
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("reify")).to.be.ok()
	end)

	it("teardown should only warn once per call site", function()
		local logInfo = Logging.capture(function()
			-- We're using a loop so that we get the same stack trace and only one
			-- warning hopefully.
			for _ = 1, 2 do
				local handle = mountWithNoop(createElement("StringValue"))
				compatReconciler.teardown(handle)
			end
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("teardown")).to.be.ok()

		logInfo = Logging.capture(function()
			-- This is a different call site, which should trigger another warning.
			local handle = mountWithNoop(createElement("StringValue"))
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
				local handle = mountWithNoop(createElement("StringValue"))
				compatReconciler.reconcile(handle, createElement("StringValue"))
				VirtualTree.unmount(handle)
			end
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("reconcile")).to.be.ok()

		logInfo = Logging.capture(function()
			-- This is a different call site, which should trigger another warning.
			local handle = mountWithNoop(createElement("StringValue"))
			compatReconciler.reconcile(handle, createElement("StringValue"))
			VirtualTree.unmount(handle)
		end)

		expect(#logInfo.warnings).to.equal(1)
		expect(logInfo.warnings[1]:find("reconcile")).to.be.ok()
	end)
end