return function()
	local SingleEventManager = require(script.Parent.SingleEventManager)

	describe("new", function()
		it("should create a SingleEventManager", function()
			local manager = SingleEventManager.new()

			expect(manager).to.be.ok()
		end)
	end)

	describe("connectEvent", function()
		it("should connect to events", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(target)
			local callCount = 0

			manager:connectEvent("Event", function(rbx, arg)
				expect(rbx).to.equal(target)
				expect(arg).to.equal("foo")
				callCount = callCount + 1
			end)

			manager:resume()

			target:Fire("foo")

			expect(callCount).to.equal(1)

			target:Fire("foo")

			expect(callCount).to.equal(2)
		end)

		it("should drop events until resumed initially", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(target)
			local callCount = 0

			manager:connectEvent("Event", function(rbx, arg)
				callCount = callCount + 1
			end)

			target:Fire("foo")
			expect(callCount).to.equal(0)

			manager:resume()
			target:Fire("foo")
			expect(callCount).to.equal(1)
		end)

		it("should invoke suspended events when resumed", function()
			local target = Instance.new("BindableEvent")
			local manager = SingleEventManager.new(target)
			local callCount = 0

			manager:connectEvent("Event", function(rbx, arg)
				expect(rbx).to.equal(target)
				expect(arg).to.equal("foo")
				callCount = callCount + 1
			end)

			manager:suspend()

			target:Fire("foo")
			expect(callCount).to.equal(0)

			manager:resume()
			expect(callCount).to.equal(1)
		end)
	end)

	describe("connectPropertyChange", function()
		it("should connect to property changes", function()
			local target = Instance.new("Folder")
			local manager = SingleEventManager.new(target)
			local changeCount = 0

			manager:connectPropertyChange("Name", function(rbx, arg)
				changeCount = changeCount + 1
			end)

			manager:resume()

			target.Name = "foo"
			expect(changeCount).to.equal(1)

			target.Name = "bar"
			expect(changeCount).to.equal(2)
		end)

		it("should drop events until resumed initially", function()
			local target = Instance.new("Folder")
			local manager = SingleEventManager.new(target)
			local changeCount = 0

			manager:connectPropertyChange("Name", function(rbx, arg)
				changeCount = changeCount + 1
			end)

			target.Name = "foo"
			expect(changeCount).to.equal(0)

			manager:resume()
			target.Name = "bar"
			expect(changeCount).to.equal(1)
		end)

		it("should invoke suspended events when resumed", function()
			local target = Instance.new("Folder")
			local manager = SingleEventManager.new(target)
			local changeCount = 0

			manager:connectPropertyChange("Name", function(rbx, arg)
				changeCount = changeCount + 1
			end)

			manager:suspend()

			target.Name = "foo"
			expect(changeCount).to.equal(0)

			manager:resume()
			expect(changeCount).to.equal(1)
		end)
	end)
end