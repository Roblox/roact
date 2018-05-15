return function()
	local Core = require(script.Parent.Core)
	local Reconciler = require(script.Parent.Reconciler)
	local createRef = require(script.Parent.createRef)

	it("should mount booleans as nil", function()
		local booleanReified = Reconciler.mount(false)
		expect(booleanReified).to.never.be.ok()
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
end