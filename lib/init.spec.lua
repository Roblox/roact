return function()
	local Roact = require(script.Parent)

	it("should load with all public APIs", function()
		local publicApi = {
			createElement = "function",
			createRef = "function",
			mount = "function",
			unmount = "function",
			update = "function",
			oneChild = "function",
			setGlobalConfig = "function",
			getGlobalConfigValue = "function",

			-- These functions are deprecated and throw warnings!
			reify = "function",
			teardown = "function",
			reconcile = "function",

			Component = true,
			PureComponent = true,
			Portal = true,
			Children = true,
			Event = true,
			Change = true,
			Ref = true,
			None = true,
			UNSTABLE = true,
		}

		expect(Roact).to.be.ok()

		for key, valueType in pairs(publicApi) do
			local success
			if typeof(valueType) == "string" then
				success = typeof(Roact[key]) == valueType
			else
				success = Roact[key] ~= nil
			end

			if not success then
				local existence = typeof(valueType) == "boolean" and "present" or "of type " .. valueType
				local message = (
					"Expected public API member %q to be %s, but instead it was of type %s"
				):format(tostring(key), existence, typeof(Roact[key]))

				error(message)
			end
		end

		for key in pairs(Roact) do
			if publicApi[key] == nil then
				local message = (
					"Found unknown public API key %q!"
				):format(tostring(key))

				error(message)
			end
		end
	end)

	describe("Context", function()
		SKIP()

		it("should be passed to children through primitive and functional components", function()
			local testValue = {}

			local callCount = 0

			local ContextConsumer = Roact.Component:extend("ContextConsumer")

			function ContextConsumer:init(props)
				expect(self._context.testValue).to.equal(testValue)

				callCount = callCount + 1
			end

			function ContextConsumer:render()
				return
			end

			local function ContextBarrier(props)
				return Roact.createElement(ContextConsumer)
			end

			local ContextProvider = Roact.Component:extend("ContextProvider")

			function ContextProvider:init(props)
				self._context.testValue = props.testValue
			end

			function ContextProvider:render()
				return Roact.createElement("Frame", {}, {
					Child = Roact.createElement(ContextBarrier),
				})
			end

			local element = Roact.createElement(ContextProvider, {
				testValue = testValue,
			})

			Roact.mount(element)

			expect(callCount).to.equal(1)
		end)
	end)

	describe("Ref", function()
		SKIP()

		it("should call back with a Roblox object after properties and children", function()
			local callCount = 0

			local function ref(rbx)
				expect(rbx).to.be.ok()
				expect(rbx.ClassName).to.equal("StringValue")
				expect(rbx.Value).to.equal("Hey!")
				expect(rbx.Name).to.equal("RefTest")
				expect(#rbx:GetChildren()).to.equal(1)

				callCount = callCount + 1
			end

			local element = Roact.createElement("StringValue", {
				Value = "Hey!",
				[Roact.Ref] = ref,
			}, {
				TestChild = Roact.createElement("StringValue"),
			})

			Roact.mount(element, nil, "RefTest")

			expect(callCount).to.equal(1)
		end)

		it("should pass nil to refs for tearing down", function()
			local callCount = 0
			local currentRef

			local function ref(rbx)
				currentRef = rbx
				callCount = callCount + 1
			end

			local element = Roact.createElement("StringValue", {
				[Roact.Ref] = ref,
			})

			local instance = Roact.mount(element, nil, "RefTest")

			expect(callCount).to.equal(1)
			expect(currentRef).to.be.ok()
			expect(currentRef.Name).to.equal("RefTest")

			Roact.unmount(instance)

			expect(callCount).to.equal(2)
			expect(currentRef).to.equal(nil)
		end)

		it("should tear down refs when switched out of the tree", function()
			local updateMethod
			local refCount = 0
			local currentRef

			local function ref(rbx)
				currentRef = rbx
				refCount = refCount + 1
			end

			local function RefWrapper()
				return Roact.createElement("StringValue", {
					Value = "ooba ooba",
					[Roact.Ref] = ref,
				})
			end

			local Root = Roact.Component:extend("RefTestRoot")

			function Root:init()
				updateMethod = function(show)
					self:setState({
						show = show,
					})
				end
			end

			function Root:render()
				if self.state.show then
					return Roact.createElement(RefWrapper)
				end
			end

			local element = Roact.createElement(Root)
			Roact.mount(element)

			expect(refCount).to.equal(0)
			expect(currentRef).to.equal(nil)

			updateMethod(true)

			expect(refCount).to.equal(1)
			expect(currentRef.Value).to.equal("ooba ooba")

			updateMethod(false)

			expect(refCount).to.equal(2)
			expect(currentRef).to.equal(nil)
		end)
	end)

	describe("Portal", function()
		SKIP()

		it("should error if the target is not a Roblox instance", function()
			local portal = Roact.createElement(Roact.Portal, {
					target = "NotARobloxInstance",
				}, {
				folderOne = Roact.createElement("Folder"),
				folderTwo = Roact.createElement("Folder"),
			})

			expect(function()
				Roact.mount(portal)
			end).to.throw()
		end)
	end)
end