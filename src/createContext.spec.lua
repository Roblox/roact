return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local Component = require(script.Parent.Component)
	local NoopRenderer = require(script.Parent.NoopRenderer)
	local Children = require(script.Parent.PropMarkers.Children)
	local createContext = require(script.Parent.createContext)
	local createElement = require(script.Parent.createElement)
	local createFragment = require(script.Parent.createFragment)
	local createReconciler = require(script.Parent.createReconciler)
	local createSpy = require(script.Parent.createSpy)

	local noopReconciler = createReconciler(NoopRenderer)

	local RobloxRenderer = require(script.Parent.RobloxRenderer)
	local robloxReconciler = createReconciler(RobloxRenderer)

	it("should return a table", function()
		local context = createContext("Test")
		expect(context).to.be.ok()
		expect(type(context)).to.equal("table")
	end)

	it("should contain a Provider and a Consumer", function()
		local context = createContext("Test")
		expect(context.Provider).to.be.ok()
		expect(context.Consumer).to.be.ok()
	end)

	describe("Provider", function()
		it("should render its children", function()
			local context = createContext("Test")

			local Listener = createSpy(function()
				return nil
			end)

			local element = createElement(context.Provider, {
				value = "Test",
			}, {
				Listener = createElement(Listener.value),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)

			expect(Listener.callCount).to.equal(1)
		end)
	end)

	describe("Consumer", function()
		it("should expect a render function", function()
			local context = createContext("Test")
			local element = createElement(context.Consumer)

			expect(function()
				noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			end).to.throw()
		end)

		it("should return the default value if there is no Provider", function()
			local valueSpy = createSpy()
			local context = createContext("Test")

			local element = createElement(context.Consumer, {
				render = valueSpy.value,
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)

			valueSpy:assertCalledWith("Test")
		end)

		it("should pass the value to the render function", function()
			local valueSpy = createSpy()
			local context = createContext("Test")

			local function Listener()
				return createElement(context.Consumer, {
					render = valueSpy.value,
				})
			end

			local element = createElement(context.Provider, {
				value = "NewTest",
			}, {
				Listener = createElement(Listener),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")
			noopReconciler.unmountVirtualTree(tree)

			valueSpy:assertCalledWith("NewTest")
		end)

		it("should update when the value updates", function()
			local valueSpy = createSpy()
			local context = createContext("Test")

			local function Listener()
				return createElement(context.Consumer, {
					render = valueSpy.value,
				})
			end

			local element = createElement(context.Provider, {
				value = "NewTest",
			}, {
				Listener = createElement(Listener),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")

			expect(valueSpy.callCount).to.equal(1)
			valueSpy:assertCalledWith("NewTest")

			noopReconciler.updateVirtualTree(
				tree,
				createElement(context.Provider, {
					value = "ThirdTest",
				}, {
					Listener = createElement(Listener),
				})
			)

			expect(valueSpy.callCount).to.equal(2)
			valueSpy:assertCalledWith("ThirdTest")

			noopReconciler.unmountVirtualTree(tree)
		end)

		--[[
			This test is the same as the one above, but with a component that
			always blocks updates in the middle. We expect behavior to be the
			same.
		]]
		it("should update when the value updates through an update blocking component", function()
			local valueSpy = createSpy()
			local context = createContext("Test")

			local UpdateBlocker = Component:extend("UpdateBlocker")

			function UpdateBlocker:render()
				return createFragment(self.props[Children])
			end

			function UpdateBlocker:shouldUpdate()
				return false
			end

			local function Listener()
				return createElement(context.Consumer, {
					render = valueSpy.value,
				})
			end

			local element = createElement(context.Provider, {
				value = "NewTest",
			}, {
				Blocker = createElement(UpdateBlocker, nil, {
					Listener = createElement(Listener),
				}),
			})

			local tree = noopReconciler.mountVirtualTree(element, nil, "Provide Tree")

			expect(valueSpy.callCount).to.equal(1)
			valueSpy:assertCalledWith("NewTest")

			noopReconciler.updateVirtualTree(
				tree,
				createElement(context.Provider, {
					value = "ThirdTest",
				}, {
					Blocker = createElement(UpdateBlocker, nil, {
						Listener = createElement(Listener),
					}),
				})
			)

			expect(valueSpy.callCount).to.equal(2)
			valueSpy:assertCalledWith("ThirdTest")

			noopReconciler.unmountVirtualTree(tree)
		end)

		it("should behave correctly when the default value is nil", function()
			local context = createContext(nil)

			local valueSpy = createSpy()
			local function Listener()
				return createElement(context.Consumer, {
					render = valueSpy.value,
				})
			end

			local tree = noopReconciler.mountVirtualTree(createElement(Listener), nil, "Provide Tree")
			expect(valueSpy.callCount).to.equal(1)
			valueSpy:assertCalledWith(nil)

			tree = noopReconciler.updateVirtualTree(tree, createElement(Listener))
			noopReconciler.unmountVirtualTree(tree)

			expect(valueSpy.callCount).to.equal(2)
			valueSpy:assertCalledWith(nil)
		end)
	end)

	describe("Update order", function()
		--[[
			This test ensures that there is no scenario where we can observe
			'update tearing' when props and context are updated at the same
			time.

			Update tearing is scenario where a single update is partially
			applied in multiple steps instead of atomically. This is observable
			by components and can lead to strange bugs or errors.

			This instance of update tearing happens when updating a prop and a
			context value in the same update. Image we represent our tree's
			state as the current prop and context versions. Our initial state
			is:

			(prop_1, context_1)

			The next state we would like to update to is:

			(prop_2, context_2)

			Under the bug reported in issue 259, Roact reaches three different
			states in sequence:

			1: (prop_1, context_1) - the initial state
			2: (prop_2, context_1) - woops!
			3: (prop_2, context_2) - correct end state

			In state 2, a user component was added that tried to access the
			current context value, which was not set at the time. This raised an
			error, because this state is not valid!

			The first proposed solution was to move the context update to happen
			before the props update. It is easy to show that this will still
			result in update tearing:

			1: (prop_1, context_1)
			2: (prop_1, context_2)
			3: (prop_2, context_2)

			Although the initial concern about newly added components observing
			old context values is fixed, there is still a state
			desynchronization between props and state.

			We would instead like the following update sequence:

			1: (prop_1, context_1)
			2: (prop_2, context_2)

			This test tries to ensure that is the case.

			The initial bug report is here:
			https://github.com/Roblox/roact/issues/259
		]]
		it("should update context at the same time as props", function()
			-- These values are used to make sure we reach both the first and
			-- second state combinations we want to visit.
			local observedA = false
			local observedB = false
			local updateCount = 0

			local context = createContext("default")

			local function Listener(props)
				return createElement(context.Consumer, {
					render = function(value)
						updateCount = updateCount + 1

						if value == "context_1" then
							expect(props.someProp).to.equal("prop_1")
							observedA = true
						elseif value == "context_2" then
							expect(props.someProp).to.equal("prop_2")
							observedB = true
						else
							error("Unexpected context value")
						end
					end,
				})
			end

			local element1 = createElement(context.Provider, {
				value = "context_1",
			}, {
				Child = createElement(Listener, {
					someProp = "prop_1",
				}),
			})

			local element2 = createElement(context.Provider, {
				value = "context_2",
			}, {
				Child = createElement(Listener, {
					someProp = "prop_2",
				}),
			})

			local tree = noopReconciler.mountVirtualTree(element1, nil, "UpdateObservationIsFun")
			noopReconciler.updateVirtualTree(tree, element2)

			expect(updateCount).to.equal(2)
			expect(observedA).to.equal(true)
			expect(observedB).to.equal(true)
		end)
	end)

	-- issue https://github.com/Roblox/roact/issues/319
	it("does not throw if willUnmount is called twice on a context consumer", function()
		local context = createContext({})

		local LowestComponent = Component:extend("LowestComponent")
		function LowestComponent:init() end

		function LowestComponent:render()
			return createElement("Frame")
		end

		function LowestComponent:didMount()
			self.props.onDidMountCallback()
		end

		local FirstComponent = Component:extend("FirstComponent")
		function FirstComponent:init() end

		function FirstComponent:render()
			return createElement(context.Consumer, {
				render = function()
					return createElement("TextLabel")
				end,
			})
		end

		local ChildComponent = Component:extend("ChildComponent")

		function ChildComponent:init()
			self:setState({ firstTime = true })
		end

		local childCallback

		function ChildComponent:render()
			if self.state.firstTime then
				return createElement(FirstComponent)
			end

			return createElement(LowestComponent, {
				onDidMountCallback = self.props.onDidMountCallback,
			})
		end

		function ChildComponent:didMount()
			childCallback = function()
				self:setState({ firstTime = false })
			end
		end

		local ParentComponent = Component:extend("ParentComponent")

		local didMountCallbackCalled = 0

		function ParentComponent:init()
			self:setState({ count = 1 })

			self.onDidMountCallback = function()
				didMountCallbackCalled = didMountCallbackCalled + 1
				if self.state.count < 5 then
					self:setState({ count = self.state.count + 1 })
				end
			end
		end

		function ParentComponent:render()
			return createElement("Frame", {}, {
				Provider = createElement(context.Provider, {
					value = {},
				}, {
					ChildComponent = createElement(ChildComponent, {
						count = self.state.count,
						onDidMountCallback = self.onDidMountCallback,
					}),
				}),
			})
		end

		local parent = Instance.new("ScreenGui")
		parent.Parent = ReplicatedStorage

		local hostKey = "Some Key"
		robloxReconciler.mountVirtualNode(createElement(ParentComponent), parent, hostKey)

		expect(function()
			-- calling setState on ChildComponent will trigger `willUnmount` multiple times
			childCallback()
		end).never.to.throw()
	end)
end
