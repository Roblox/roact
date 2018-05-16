return function()
	local Core = require(script.Parent.Core)
	local Reconciler = require(script.Parent.Reconciler)
	local Event = require(script.Parent.Event)
	local Change = require(script.Parent.Change)
	local GlobalConfig = require(script.Parent.GlobalConfig)
	local createRef = require(script.Parent.createRef)

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

	it("should handle object references properly", function()
		local objectRef = createRef()
		local element = Core.createElement("StringValue", {
			[Core.Ref] = objectRef,
		})

		local handle = Reconciler.mount(element)
		expect(objectRef.current).to.be.ok()
		Reconciler.unmount(handle)
		expect(objectRef.current).to.never.be.ok()
	end)

	it("should handle function references properly", function()
		local currentRbx

		local function ref(rbx)
			currentRbx = rbx
		end

		local element = Core.createElement("StringValue", {
			[Core.Ref] = ref,
		})

		local handle = Reconciler.mount(element)
		expect(currentRbx).to.be.ok()
		Reconciler.unmount(handle)
		expect(currentRbx).to.never.be.ok()
	end)

	it("should handle changing function references", function()
		local aValue, bValue

		local function aRef(rbx)
			aValue = rbx
		end

		local function bRef(rbx)
			bValue = rbx
		end

		local element = Core.createElement("StringValue", {
			[Core.Ref] = aRef,
		})

		local handle = Reconciler.mount(element, game, "Test123")
		expect(aValue).to.be.ok()
		expect(bValue).to.never.be.ok()
		handle = Reconciler.reconcile(handle, Core.createElement("StringValue", {
			[Core.Ref] = bRef,
		}))
		expect(aValue).to.never.be.ok()
		expect(bValue).to.be.ok()
		Reconciler.unmount(handle)
		expect(bValue).to.never.be.ok()
	end)

	it("should handle changing object references", function()
		local aRef = createRef()
		local bRef = createRef()

		local element = Core.createElement("StringValue", {
			[Core.Ref] = aRef,
		})

		local handle = Reconciler.mount(element, game, "Test123")
		expect(aRef.current).to.be.ok()
		expect(bRef.current).to.never.be.ok()
		handle = Reconciler.reconcile(handle, Core.createElement("StringValue", {
			[Core.Ref] = bRef,
		}))
		expect(aRef.current).to.never.be.ok()
		expect(bRef.current).to.be.ok()
		Reconciler.unmount(handle)
		expect(bRef.current).to.never.be.ok()
	end)
end