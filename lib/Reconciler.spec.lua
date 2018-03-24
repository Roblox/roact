return function()
	local Reconciler = require(script.Parent.Reconciler)
	local Core = require(script.Parent.Core)
	local Event = require(script.Parent.Event)
	local GlobalConfig = require(script.Parent.GlobalConfig)

	it("should reify booleans as nil", function()
		local booleanReified = Reconciler.reify(false)
		expect(booleanReified).to.never.be.ok()
	end)

	describe("tracing", function()
		GlobalConfig.set({
			logAllMutations = true
		})

		it("should print when properties are set", function()
			local traceCount = 0

			Reconciler._traceFunction = function()
				traceCount = traceCount + 1
			end

			local element = Core.createElement("IntValue", {
				Value = 0
			})

			local handle = Reconciler.reify(element)
			expect(traceCount).to.equal(1)

			Reconciler.reconcile(handle, Core.createElement("IntValue", {
				Value = 1
			}))

			expect(traceCount).to.equal(2)
		end)

		it("should print when events are connected", function()
			local traceCount = 0

			Reconciler._traceFunction = function()
				traceCount = traceCount + 1
			end

			local element = Core.createElement("IntValue", {
				[Event.Changed] = function() end,
			})

			local handle = Reconciler.reify(element)
			expect(traceCount).to.equal(1)

			Reconciler.reconcile(handle, Core.createElement("IntValue", {
				[Event.Changed] = function() end,
			}))

			expect(traceCount).to.equal(2)
		end)
	end)
end