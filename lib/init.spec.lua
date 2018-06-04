return function()
	local Roact = require(script.Parent)

	it("should load with all public APIs", function()
		local publicApi = {
			createElement = "function",
			createRef = "function",
			mount = "function",
			unmount = "function",
			reconcile = "function",
			oneChild = "function",
			setGlobalConfig = "function",
			getGlobalConfigValue = "function",

			-- These functions are deprecated and will throw warnings soon!
			reify = "function",
			teardown = "function",

			Component = true,
			PureComponent = true,
			Portal = true,
			Children = true,
			Event = true,
			Change = true,
			Ref = true,
			None = true,
			Element = true,
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

	describe("Props", function()
		it("should be passed to primitive components", function()
			local container = Instance.new("IntValue")

			local element = Roact.createElement("StringValue", {
				Value = "foo",
			})

			Roact.mount(element, container, "TestStringValue")

			local rbx = container:FindFirstChild("TestStringValue")

			expect(rbx).to.be.ok()
			expect(rbx.Value).to.equal("foo")
		end)

		it("should be passed to functional components", function()
			local testProp = {}

			local callCount = 0

			local function TestComponent(props)
				expect(props.testProp).to.equal(testProp)
				callCount = callCount + 1
			end

			local element = Roact.createElement(TestComponent, {
				testProp = testProp,
			})

			Roact.mount(element)

			-- The only guarantee is that the function will be invoked at least once
			expect(callCount > 0).to.equal(true)
		end)

		it("should be passed to stateful components", function()
			local testProp = {}

			local callCount = 0

			local TestComponent = Roact.Component:extend("TestComponent")

			function TestComponent:init(props)
				expect(props.testProp).to.equal(testProp)
				callCount = callCount + 1
			end

			function TestComponent:render()
			end

			local element = Roact.createElement(TestComponent, {
				testProp = testProp,
			})

			Roact.mount(element)

			expect(callCount).to.equal(1)
		end)
	end)

	describe("State", function()
		it("should trigger a re-render of child components", function()
			local renderCount = 0
			local listener = nil

			local TestChild = Roact.Component:extend("TestChild")

			function TestChild:render()
				renderCount = renderCount + 1
				return nil
			end

			local TestParent = Roact.Component:extend("TestParent")

			function TestParent:init(props)
				self.state = {
					value = 0,
				}
			end

			function TestParent:didMount()
				listener = function()
					self:setState({
						value = self.state.value + 1,
					})
				end
			end

			function TestParent:render()
				return Roact.createElement(TestChild, {
					value = self.state.value,
				})
			end

			local element = Roact.createElement(TestParent)
			Roact.mount(element)

			expect(renderCount >= 1).to.equal(true)
			expect(listener).to.be.a("function")

			listener()

			expect(renderCount >= 2).to.equal(true)
		end)
	end)

	describe("Context", function()
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
		it("should place all children as children of the target Roblox instance", function()
			local target = Instance.new("Folder")

			local function FunctionalComponent(props)
				local intValue = props.value

				return Roact.createElement("IntValue", {
					Value = intValue,
				})
			end

			local portal = Roact.createElement(Roact.Portal, {
				target = target
			}, {
				folderOne = Roact.createElement("Folder"),
				folderTwo = Roact.createElement("Folder"),
				intValueOne = Roact.createElement(FunctionalComponent, {
					value = 42,
				}),
			})
			Roact.mount(portal)

			expect(target:FindFirstChild("folderOne")).to.be.ok()
			expect(target:FindFirstChild("folderTwo")).to.be.ok()
			expect(target:FindFirstChild("intValueOne")).to.be.ok()
			expect(target:FindFirstChild("intValueOne").Value).to.equal(42)
		end)

		it("should error if the target is nil", function()
			local portal = Roact.createElement(Roact.Portal, {}, {
				folderOne = Roact.createElement("Folder"),
				folderTwo = Roact.createElement("Folder"),
			})

			expect(function()
				Roact.mount(portal)
			end).to.throw()
		end)

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

		it("should update if parent changes the target", function()
			local targetOne = Instance.new("Folder")
			local targetTwo = Instance.new("Folder")
			local countWillUnmount = 0
			local changeState

			local TestUnmountComponent = Roact.Component:extend("TestUnmountComponent")

			function TestUnmountComponent:render()
				return nil
			end

			function TestUnmountComponent:willUnmount()
				countWillUnmount = countWillUnmount + 1
			end

			local PortalContainer = Roact.Component:extend("PortalContainer")

			function PortalContainer:init()
				self.state = {
					target = targetOne,
				}
			end

			function PortalContainer:render()
				return Roact.createElement(Roact.Portal, {
					target = self.state.target,
				}, {
					folderOne = Roact.createElement("Folder"),
					folderTwo = Roact.createElement("Folder"),
					testUnmount = Roact.createElement(TestUnmountComponent),
				})
			end

			function PortalContainer:didMount()
				expect(self.state.target:FindFirstChild("folderOne")).to.be.ok()
				expect(self.state.target:FindFirstChild("folderTwo")).to.be.ok()

				changeState = function(newState)
					self:setState(newState)
				end
			end

			Roact.mount(Roact.createElement(PortalContainer))

			expect(targetOne:FindFirstChild("folderOne")).to.be.ok()
			expect(targetOne:FindFirstChild("folderTwo")).to.be.ok()

			changeState({
				target = targetTwo,
			})

			expect(countWillUnmount).to.equal(1)

			expect(targetOne:FindFirstChild("folderOne")).never.to.be.ok()
			expect(targetOne:FindFirstChild("folderTwo")).never.to.be.ok()
			expect(targetTwo:FindFirstChild("folderOne")).to.be.ok()
			expect(targetTwo:FindFirstChild("folderTwo")).to.be.ok()
		end)

		it("should update Roblox instance properties when relevant parent props are changed", function()
			local target = Instance.new("Folder")
			local changeState

			local PortalContainer = Roact.Component:extend("PortalContainer")

			function PortalContainer:init()
				self.state = {
					value = "initialStringValue",
				}
			end

			function PortalContainer:render()
				return Roact.createElement(Roact.Portal, {
					target = target,
				}, {
					TestStringValue = Roact.createElement("StringValue", {
						Value = self.state.value,
					})
				})
			end

			function PortalContainer:didMount()
				changeState = function(newState)
					self:setState(newState)
				end
			end

			Roact.mount(Roact.createElement(PortalContainer))

			expect(target:FindFirstChild("TestStringValue")).to.be.ok()
			expect(target:FindFirstChild("TestStringValue").Value).to.equal("initialStringValue")

			changeState({
				value = "newStringValue",
			})

			expect(target:FindFirstChild("TestStringValue")).to.be.ok()
			expect(target:FindFirstChild("TestStringValue").Value).to.equal("newStringValue")
		end)

		it("should properly teardown the Portal", function()
			local target = Instance.new("Folder")

			local portal = Roact.createElement(Roact.Portal, {
				target = target
			}, {
				folderOne = Roact.createElement("Folder"),
				folderTwo = Roact.createElement("Folder"),
			})
			local instance = Roact.mount(portal)

			local folderThree = Instance.new("Folder")
			folderThree.Name = "folderThree"
			folderThree.Parent = target

			expect(target:FindFirstChild("folderOne")).to.be.ok()
			expect(target:FindFirstChild("folderTwo")).to.be.ok()
			expect(target:FindFirstChild("folderThree")).to.be.ok()

			Roact.unmount(instance)

			expect(target:FindFirstChild("folderOne")).never.to.be.ok()
			expect(target:FindFirstChild("folderTwo")).never.to.be.ok()
			expect(target:FindFirstChild("folderThree")).to.be.ok()
		end)
	end)
end