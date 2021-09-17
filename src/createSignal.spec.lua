return function()
	local createSignal = require(script.Parent.createSignal)

	local createSpy = require(script.Parent.createSpy)

	it("should fire subscribers and disconnect them", function()
		local signal = createSignal()

		local spy = createSpy()
		local disconnect = signal:subscribe(spy.value)

		expect(spy.callCount).to.equal(0)

		local a = 1
		local b = {}
		local c = "hello"
		signal:fire(a, b, c)

		expect(spy.callCount).to.equal(1)
		spy:assertCalledWith(a, b, c)

		disconnect()

		signal:fire()

		expect(spy.callCount).to.equal(1)
	end)

	it("should handle multiple subscribers", function()
		local signal = createSignal()

		local spyA = createSpy()
		local spyB = createSpy()

		local disconnectA = signal:subscribe(spyA.value)
		local disconnectB = signal:subscribe(spyB.value)

		expect(spyA.callCount).to.equal(0)
		expect(spyB.callCount).to.equal(0)

		local a = {}
		local b = 67
		signal:fire(a, b)

		expect(spyA.callCount).to.equal(1)
		spyA:assertCalledWith(a, b)

		expect(spyB.callCount).to.equal(1)
		spyB:assertCalledWith(a, b)

		disconnectA()

		signal:fire(b, a)

		expect(spyA.callCount).to.equal(1)

		expect(spyB.callCount).to.equal(2)
		spyB:assertCalledWith(b, a)

		disconnectB()
	end)

	it("should stop firing a connection if disconnected mid-fire", function()
		local signal = createSignal()

		-- In this test, we'll connect two listeners that each try to disconnect
		-- the other. Because the order of listeners firing isn't defined, we
		-- have to be careful to handle either case.

		local disconnectA
		local disconnectB

		local spyA = createSpy(function()
			disconnectB()
		end)

		local spyB = createSpy(function()
			disconnectA()
		end)

		disconnectA = signal:subscribe(spyA.value)
		disconnectB = signal:subscribe(spyB.value)

		signal:fire()

		-- Exactly once listener should have been called.
		expect(spyA.callCount + spyB.callCount).to.equal(1)
	end)

	it("should allow adding listener in the middle of firing", function()
		local signal = createSignal()

		local disconnectA
		local spyA = createSpy()
		local listener = function(_a, _b)
			disconnectA = signal:subscribe(spyA.value)
		end

		local disconnectListener = signal:subscribe(listener)

		expect(spyA.callCount).to.equal(0)

		local a = {}
		local b = 67
		signal:fire(a, b)

		expect(spyA.callCount).to.equal(0)

		-- The new listener should be picked up in next fire.
		signal:fire(b, a)
		expect(spyA.callCount).to.equal(1)
		spyA:assertCalledWith(b, a)

		disconnectA()
		disconnectListener()

		signal:fire(a)

		expect(spyA.callCount).to.equal(1)
	end)

	it("should have one connection instance when add the same listener multiple times", function()
		local signal = createSignal()

		local spyA = createSpy()
		local disconnect1 = signal:subscribe(spyA.value)

		expect(spyA.callCount).to.equal(0)

		local a = {}
		local b = 67
		signal:fire(a, b)

		expect(spyA.callCount).to.equal(1)
		spyA:assertCalledWith(a, b)

		local disconnect2 = signal:subscribe(spyA.value)

		signal:fire(b, a)
		expect(spyA.callCount).to.equal(2)
		spyA:assertCalledWith(b, a)

		disconnect2()

		signal:fire(a)

		expect(spyA.callCount).to.equal(2)

		-- should have no effect.
		disconnect1()
		signal:fire(a)
		expect(spyA.callCount).to.equal(2)
	end)
end
