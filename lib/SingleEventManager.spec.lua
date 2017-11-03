return function()
	local SingleEventManager = require(script.Parent.SingleEventManager)

	describe("new", function()
		it("should create a SingleEventManager", function()
			local manager = SingleEventManager.new()

			expect(manager).to.be.ok()
		end)
	end)

	describe("connect", function()
		it("should connect to events on an object", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new()

			local callCount = 0

			manager:connect(target, "Event", function(rbx, arg)
				expect(rbx).to.equal(target)
				expect(arg).to.equal("foo")
				callCount = callCount + 1
			end)

			target:Fire("foo")

			expect(callCount).to.equal(1)

			target:Fire("foo")

			expect(callCount).to.equal(2)
		end)

		it("should only connect one handler at a time", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new()

			local callCountA = 0
			local callCountB = 0

			manager:connect(target, "Event", function(rbx)
				expect(rbx).to.equal(target)
				callCountA = callCountA + 1
			end)

			manager:connect(target, "Event", function(rbx)
				expect(rbx).to.equal(target)
				callCountB = callCountB + 1
			end)

			target:Fire("foo")

			expect(callCountA).to.equal(0)
			expect(callCountB).to.equal(1)
		end)

		it("shouldn't conflate different event handlers", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new()

			local callCountEvent = 0
			local callCountChanged = 0

			manager:connect(target, "Event", function(rbx)
				expect(rbx).to.equal(target)
				callCountEvent = callCountEvent + 1
			end)

			manager:connect(target, "Changed", function(rbx)
				expect(rbx).to.equal(target)
				callCountChanged = callCountChanged + 1
			end)

			target:Fire()

			expect(callCountEvent).to.equal(1)
			expect(callCountChanged).to.equal(0)

			target.Name = "unlimited power!"

			expect(callCountEvent).to.equal(1)
			expect(callCountChanged).to.equal(1)
		end)
	end)

	describe("disconnect", function()
		it("should disconnect handlers on an object", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new()

			local callCount = 0

			manager:connect(target, "Event", function(rbx)
				expect(rbx).to.equal(target)
				callCount = callCount + 1
			end)

			target:Fire()

			expect(callCount).to.equal(1)

			manager:disconnect(target, "Event")

			target:Fire()

			expect(callCount).to.equal(1)
		end)

		it("should not disconnect unrelated connections", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new()

			local callCountEvent = 0
			local callCountChanged = 0

			manager:connect(target, "Event", function(rbx)
				expect(rbx).to.equal(target)
				callCountEvent = callCountEvent + 1
			end)

			manager:connect(target, "Changed", function(rbx)
				expect(rbx).to.equal(target)
				callCountChanged = callCountChanged + 1
			end)

			target:Fire()
			target.Name = "bar"

			expect(callCountEvent).to.equal(1)
			expect(callCountChanged).to.equal(1)

			manager:disconnect(target, "Event")

			target:Fire()
			target.Name = "foo"

			expect(callCountEvent).to.equal(1)
			expect(callCountChanged).to.equal(2)
		end)

		it("should succeed with no events attached", function()
			local manager = SingleEventManager.new()
			local target = Instance.new("StringValue")

			manager:disconnect(target, "Event")
		end)
	end)

	describe("disconnectAll", function()
		it("should disconnect all listeners on an object", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new()

			local callCountEvent = 0
			local callCountChanged = 0

			manager:connect(target, "Event", function(rbx)
				expect(rbx).to.equal(target)
				callCountEvent = callCountEvent + 1
			end)

			manager:connect(target, "Changed", function(rbx)
				expect(rbx).to.equal(target)
				callCountChanged = callCountChanged + 1
			end)

			target:Fire()
			target.Name = "bar"

			expect(callCountEvent).to.equal(1)
			expect(callCountChanged).to.equal(1)

			manager:disconnectAll(target)

			target:Fire()
			target.Name = "foo"

			expect(callCountEvent).to.equal(1)
			expect(callCountChanged).to.equal(1)
		end)

		it("should succeed with no events attached", function()
			local target = Instance.new("StringValue")
			local manager = SingleEventManager.new()

			manager:disconnectAll(target)
		end)
	end)
end