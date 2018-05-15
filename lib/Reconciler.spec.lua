return function()
	local Reconciler = require(script.Parent.Reconciler)
	local Core = require(script.Parent.Core)
	local Event = require(script.Parent.Event)
	local Change = require(script.Parent.Change)
	local GlobalConfig = require(script.Parent.GlobalConfig)

	it("should mount booleans as nil", function()
		local booleanReified = Reconciler.mount(false)
		expect(booleanReified).to.never.be.ok()
	end)

	describe("tracing", function()
		it("should print when properties are set", function()
			GlobalConfig.set({
				logAllMutations = true
			})

			local traceCount = 0

			Reconciler._traceFunction = function()
				traceCount = traceCount + 1
			end

			local element = Core.createElement("IntValue", {
				Value = 0
			})

			local handle = Reconciler.mount(element)
			expect(traceCount).to.equal(1)

			Reconciler.reconcile(handle, Core.createElement("IntValue", {
				Value = 1
			}))

			expect(traceCount).to.equal(2)

			Reconciler.unmount(handle)
			GlobalConfig.reset()
		end)

		it("should print when events are connected", function()
			GlobalConfig.set({
				logAllMutations = true
			})

			local traceCount = 0

			Reconciler._traceFunction = function()
				traceCount = traceCount + 1
			end

			local element = Core.createElement("IntValue", {
				[Event.Changed] = function() end,
			})

			local handle = Reconciler.mount(element)
			expect(traceCount).to.equal(1)

			Reconciler.reconcile(handle, Core.createElement("IntValue", {
				[Event.Changed] = function() end,
			}))

			expect(traceCount).to.equal(2)

			Reconciler.unmount(handle)
			GlobalConfig.reset()
		end)

		it("should print when property change listeners are connected", function()
			GlobalConfig.set({
				logAllMutations = true
			})

			local traceCount = 0

			Reconciler._traceFunction = function()
				traceCount = traceCount + 1
			end

			local element = Core.createElement("IntValue", {
				[Change.Name] = function() end,
			})

			local handle = Reconciler.mount(element)
			expect(traceCount).to.equal(1)

			Reconciler.reconcile(handle, Core.createElement("IntValue", {
				[Change.Name] = function() end,
			}))

			expect(traceCount).to.equal(2)

			Reconciler.unmount(handle)
			GlobalConfig.reset()
		end)

		it("should not print when logAllMutations is not true", function()
			local traceCount = 0

			Reconciler._traceFunction = function()
				traceCount = traceCount + 1
			end

			local element = Core.createElement("StringValue", {
				Value = "Test",
				[Event.Changed] = function() end,
				[Change.Value] = function() end,
			})

			local handle = Reconciler.mount(element)
			expect(traceCount).to.equal(0)

			handle = Reconciler.reconcile(handle, Core.createElement("StringValue", {
				[Change.Value] = function() end,
			}))

			expect(traceCount).to.equal(0)

			Reconciler.unmount(handle)
		end)
	end)
end