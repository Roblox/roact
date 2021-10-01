return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")

	local assertDeepEqual = require(script.Parent.assertDeepEqual)
	local Binding = require(script.Parent.Binding)
	local Children = require(script.Parent.PropMarkers.Children)
	local Component = require(script.Parent.Component)
	local createElement = require(script.Parent.createElement)
	local createFragment = require(script.Parent.createFragment)
	local createReconciler = require(script.Parent.createReconciler)
	local createRef = require(script.Parent.createRef)
	local createSpy = require(script.Parent.createSpy)
	local GlobalConfig = require(script.Parent.GlobalConfig)
	local Portal = require(script.Parent.Portal)
	local Ref = require(script.Parent.PropMarkers.Ref)
	local Event = require(script.Parent.PropMarkers.Event)

	local RobloxRenderer = require(script.Parent.RobloxRenderer)

	local reconciler = createReconciler(RobloxRenderer)

	describe("mountHostNode", function()
		it("should create instances with correct props", function()
			local parent = Instance.new("Folder")
			local value = "Hello!"
			local key = "Some Key"

			local element = createElement("StringValue", {
				Value = value,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local root = parent:GetChildren()[1]

			expect(root.ClassName).to.equal("StringValue")
			expect(root.Value).to.equal(value)
			expect(root.Name).to.equal(key)
		end)

		it("should create children with correct names and props", function()
			local parent = Instance.new("Folder")
			local rootValue = "Hey there!"
			local childValue = 173
			local key = "Some Key"

			local element = createElement("StringValue", {
				Value = rootValue,
			}, {
				ChildA = createElement("IntValue", {
					Value = childValue,
				}),

				ChildB = createElement("Folder"),
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local root = parent:GetChildren()[1]

			expect(root.ClassName).to.equal("StringValue")
			expect(root.Value).to.equal(rootValue)
			expect(root.Name).to.equal(key)

			expect(#root:GetChildren()).to.equal(2)

			local childA = root.ChildA
			local childB = root.ChildB

			expect(childA).to.be.ok()
			expect(childB).to.be.ok()

			expect(childA.ClassName).to.equal("IntValue")
			expect(childA.Value).to.equal(childValue)

			expect(childB.ClassName).to.equal("Folder")
		end)

		it("should attach Bindings to Roblox properties", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local binding, update = Binding.create(10)
			local element = createElement("IntValue", {
				Value = binding,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local instance = parent:GetChildren()[1]

			expect(instance.ClassName).to.equal("IntValue")
			expect(instance.Value).to.equal(10)

			update(20)

			expect(instance.Value).to.equal(20)

			RobloxRenderer.unmountHostNode(reconciler, node)
		end)

		it("should connect Binding refs", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local ref = createRef()
			local element = createElement("Frame", {
				[Ref] = ref,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local instance = parent:GetChildren()[1]

			expect(ref.current).to.be.ok()
			expect(ref.current).to.equal(instance)

			RobloxRenderer.unmountHostNode(reconciler, node)
		end)

		it("should call function refs", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local spyRef = createSpy()
			local element = createElement("Frame", {
				[Ref] = spyRef.value,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local instance = parent:GetChildren()[1]

			expect(spyRef.callCount).to.equal(1)
			spyRef:assertCalledWith(instance)

			RobloxRenderer.unmountHostNode(reconciler, node)
		end)

		it("should throw if setting invalid instance properties", function()
			local configValues = {
				elementTracing = true,
			}

			GlobalConfig.scoped(configValues, function()
				local parent = Instance.new("Folder")
				local key = "Some Key"

				local element = createElement("Frame", {
					Frob = 6,
				})

				local node = reconciler.createVirtualNode(element, parent, key)

				local success, message = pcall(RobloxRenderer.mountHostNode, reconciler, node)
				assert(not success, "Expected call to fail")

				expect(message:find("Frob")).to.be.ok()
				expect(message:find("Frame")).to.be.ok()
				expect(message:find("RobloxRenderer%.spec")).to.be.ok()
			end)
		end)
	end)

	describe("updateHostNode", function()
		it("should update node props and children", function()
			-- TODO: Break up test

			local parent = Instance.new("Folder")
			local key = "updateHostNodeTest"
			local firstValue = "foo"
			local newValue = "bar"

			local defaultStringValue = Instance.new("StringValue").Value

			local element = createElement("StringValue", {
				Value = firstValue,
			}, {
				ChildA = createElement("IntValue", {
					Value = 1,
				}),
				ChildB = createElement("BoolValue", {
					Value = true,
				}),
				ChildC = createElement("StringValue", {
					Value = "test",
				}),
				ChildD = createElement("StringValue", {
					Value = "test",
				}),
			})

			local node = reconciler.createVirtualNode(element, parent, key)
			RobloxRenderer.mountHostNode(reconciler, node)

			-- Not testing mountHostNode's work here, only testing that the
			-- node is properly updated.

			local newElement = createElement("StringValue", {
				Value = newValue,
			}, {
				-- ChildA changes element type.
				ChildA = createElement("StringValue", {
					Value = "test",
				}),
				-- ChildB changes child properties.
				ChildB = createElement("BoolValue", {
					Value = false,
				}),
				-- ChildC should reset its Value property back to the default.
				ChildC = createElement("StringValue", {}),
				-- ChildD is deleted.
				-- ChildE is added.
				ChildE = createElement("Folder", {}),
			})

			RobloxRenderer.updateHostNode(reconciler, node, newElement)

			local root = parent[key]
			expect(root.ClassName).to.equal("StringValue")
			expect(root.Value).to.equal(newValue)
			expect(#root:GetChildren()).to.equal(4)

			local childA = root.ChildA
			expect(childA.ClassName).to.equal("StringValue")
			expect(childA.Value).to.equal("test")

			local childB = root.ChildB
			expect(childB.ClassName).to.equal("BoolValue")
			expect(childB.Value).to.equal(false)

			local childC = root.ChildC
			expect(childC.ClassName).to.equal("StringValue")
			expect(childC.Value).to.equal(defaultStringValue)

			local childE = root.ChildE
			expect(childE.ClassName).to.equal("Folder")
		end)

		it("should update Bindings", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local bindingA, updateA = Binding.create(10)
			local element = createElement("IntValue", {
				Value = bindingA,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			local instance = parent:GetChildren()[1]

			expect(instance.Value).to.equal(10)

			local bindingB, updateB = Binding.create(99)
			local newElement = createElement("IntValue", {
				Value = bindingB,
			})

			RobloxRenderer.updateHostNode(reconciler, node, newElement)

			expect(instance.Value).to.equal(99)

			updateA(123)

			expect(instance.Value).to.equal(99)

			updateB(123)

			expect(instance.Value).to.equal(123)

			RobloxRenderer.unmountHostNode(reconciler, node)
		end)

		it("should update Binding refs", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local refA = createRef()
			local refB = createRef()

			local element = createElement("Frame", {
				[Ref] = refA,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local instance = parent:GetChildren()[1]

			expect(refA.current).to.equal(instance)
			expect(refB.current).never.to.be.ok()

			local newElement = createElement("Frame", {
				[Ref] = refB,
			})

			RobloxRenderer.updateHostNode(reconciler, node, newElement)

			expect(refA.current).never.to.be.ok()
			expect(refB.current).to.equal(instance)

			RobloxRenderer.unmountHostNode(reconciler, node)
		end)

		it("should call old function refs with nil and new function refs with a valid rbx", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local spyRefA = createSpy()
			local spyRefB = createSpy()

			local element = createElement("Frame", {
				[Ref] = spyRefA.value,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local instance = parent:GetChildren()[1]

			expect(spyRefA.callCount).to.equal(1)
			spyRefA:assertCalledWith(instance)
			expect(spyRefB.callCount).to.equal(0)

			local newElement = createElement("Frame", {
				[Ref] = spyRefB.value,
			})

			RobloxRenderer.updateHostNode(reconciler, node, newElement)

			expect(spyRefA.callCount).to.equal(2)
			spyRefA:assertCalledWith(nil)
			expect(spyRefB.callCount).to.equal(1)
			spyRefB:assertCalledWith(instance)

			RobloxRenderer.unmountHostNode(reconciler, node)
		end)

		it("should not call function refs again if they didn't change", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local spyRef = createSpy()

			local element = createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
				[Ref] = spyRef.value,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local instance = parent:GetChildren()[1]

			expect(spyRef.callCount).to.equal(1)
			spyRef:assertCalledWith(instance)

			local newElement = createElement("Frame", {
				Size = UDim2.new(0.5, 0, 0.5, 0),
				[Ref] = spyRef.value,
			})

			RobloxRenderer.updateHostNode(reconciler, node, newElement)

			-- Not called again
			expect(spyRef.callCount).to.equal(1)
		end)

		it("should throw if setting invalid instance properties", function()
			local configValues = {
				elementTracing = true,
			}

			GlobalConfig.scoped(configValues, function()
				local parent = Instance.new("Folder")
				local key = "Some Key"

				local firstElement = createElement("Frame")
				local secondElement = createElement("Frame", {
					Frob = 6,
				})

				local node = reconciler.createVirtualNode(firstElement, parent, key)
				RobloxRenderer.mountHostNode(reconciler, node)

				local success, message = pcall(RobloxRenderer.updateHostNode, reconciler, node, secondElement)
				assert(not success, "Expected call to fail")

				expect(message:find("Frob")).to.be.ok()
				expect(message:find("Frame")).to.be.ok()
				expect(message:find("RobloxRenderer%.spec")).to.be.ok()
			end)
		end)

		it("should delete instances when reconciling to nil children", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local element = createElement("Frame", {
				Size = UDim2.new(1, 0, 1, 0),
			}, {
				child = createElement("Frame"),
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(#parent:GetChildren()).to.equal(1)

			local instance = parent:GetChildren()[1]
			expect(#instance:GetChildren()).to.equal(1)

			local newElement = createElement("Frame", {
				Size = UDim2.new(0.5, 0, 0.5, 0),
			})

			RobloxRenderer.updateHostNode(reconciler, node, newElement)
			expect(#instance:GetChildren()).to.equal(0)
		end)
	end)

	describe("unmountHostNode", function()
		it("should delete instances from the inside-out", function()
			local parent = Instance.new("Folder")
			local key = "Root"
			local element = createElement("Folder", nil, {
				Child = createElement("Folder", nil, {
					Grandchild = createElement("Folder"),
				}),
			})

			local node = reconciler.mountVirtualNode(element, parent, key)

			expect(#parent:GetChildren()).to.equal(1)

			local root = parent:GetChildren()[1]
			expect(#root:GetChildren()).to.equal(1)

			local child = root:GetChildren()[1]
			expect(#child:GetChildren()).to.equal(1)

			local grandchild = child:GetChildren()[1]

			RobloxRenderer.unmountHostNode(reconciler, node)

			expect(grandchild.Parent).to.equal(nil)
			expect(child.Parent).to.equal(nil)
			expect(root.Parent).to.equal(nil)
		end)

		it("should unsubscribe from any Bindings", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local binding, update = Binding.create(10)
			local element = createElement("IntValue", {
				Value = binding,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			local instance = parent:GetChildren()[1]

			expect(instance.Value).to.equal(10)

			RobloxRenderer.unmountHostNode(reconciler, node)
			update(56)

			expect(instance.Value).to.equal(10)
		end)

		it("should clear Binding refs", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local ref = createRef()
			local element = createElement("Frame", {
				[Ref] = ref,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(ref.current).to.be.ok()

			RobloxRenderer.unmountHostNode(reconciler, node)

			expect(ref.current).never.to.be.ok()
		end)

		it("should call function refs with nil", function()
			local parent = Instance.new("Folder")
			local key = "Some Key"

			local spyRef = createSpy()
			local element = createElement("Frame", {
				[Ref] = spyRef.value,
			})

			local node = reconciler.createVirtualNode(element, parent, key)

			RobloxRenderer.mountHostNode(reconciler, node)

			expect(spyRef.callCount).to.equal(1)

			RobloxRenderer.unmountHostNode(reconciler, node)

			expect(spyRef.callCount).to.equal(2)
			spyRef:assertCalledWith(nil)
		end)
	end)

	describe("Portals", function()
		it("should create and destroy instances as children of `target`", function()
			local target = Instance.new("Folder")

			local function FunctionComponent(props)
				return createElement("IntValue", {
					Value = props.value,
				})
			end

			local element = createElement(Portal, {
				target = target,
			}, {
				folderOne = createElement("Folder"),
				folderTwo = createElement("Folder"),
				intValueOne = createElement(FunctionComponent, {
					value = 42,
				}),
			})
			local hostParent = nil
			local hostKey = "Some Key"
			local node = reconciler.mountVirtualNode(element, hostParent, hostKey)

			expect(#target:GetChildren()).to.equal(3)

			expect(target:FindFirstChild("folderOne")).to.be.ok()
			expect(target:FindFirstChild("folderTwo")).to.be.ok()
			expect(target:FindFirstChild("intValueOne")).to.be.ok()
			expect(target:FindFirstChild("intValueOne").Value).to.equal(42)

			reconciler.unmountVirtualNode(node)

			expect(#target:GetChildren()).to.equal(0)
		end)

		it("should pass prop updates through to children", function()
			local target = Instance.new("Folder")

			local firstElement = createElement(Portal, {
				target = target,
			}, {
				ChildValue = createElement("IntValue", {
					Value = 1,
				}),
			})

			local secondElement = createElement(Portal, {
				target = target,
			}, {
				ChildValue = createElement("IntValue", {
					Value = 2,
				}),
			})

			local hostParent = nil
			local hostKey = "A Host Key"
			local node = reconciler.mountVirtualNode(firstElement, hostParent, hostKey)

			expect(#target:GetChildren()).to.equal(1)

			local firstValue = target.ChildValue
			expect(firstValue.Value).to.equal(1)

			node = reconciler.updateVirtualNode(node, secondElement)

			expect(#target:GetChildren()).to.equal(1)

			local secondValue = target.ChildValue
			expect(firstValue).to.equal(secondValue)
			expect(secondValue.Value).to.equal(2)

			reconciler.unmountVirtualNode(node)

			expect(#target:GetChildren()).to.equal(0)
		end)

		it("should throw if `target` is nil", function()
			-- TODO: Relax this restriction?
			local element = createElement(Portal)
			local hostParent = nil
			local hostKey = "Keys for Everyone"

			expect(function()
				reconciler.mountVirtualNode(element, hostParent, hostKey)
			end).to.throw()
		end)

		it("should throw if `target` is not a Roblox instance", function()
			local element = createElement(Portal, {
				target = {},
			})
			local hostParent = nil
			local hostKey = "Unleash the keys!"

			expect(function()
				reconciler.mountVirtualNode(element, hostParent, hostKey)
			end).to.throw()
		end)

		it("should recreate instances if `target` changes in an update", function()
			local firstTarget = Instance.new("Folder")
			local secondTarget = Instance.new("Folder")

			local firstElement = createElement(Portal, {
				target = firstTarget,
			}, {
				ChildValue = createElement("IntValue", {
					Value = 1,
				}),
			})

			local secondElement = createElement(Portal, {
				target = secondTarget,
			}, {
				ChildValue = createElement("IntValue", {
					Value = 2,
				}),
			})

			local hostParent = nil
			local hostKey = "Some Key"
			local node = reconciler.mountVirtualNode(firstElement, hostParent, hostKey)

			expect(#firstTarget:GetChildren()).to.equal(1)
			expect(#secondTarget:GetChildren()).to.equal(0)

			local firstChild = firstTarget.ChildValue
			expect(firstChild.Value).to.equal(1)

			node = reconciler.updateVirtualNode(node, secondElement)

			expect(#firstTarget:GetChildren()).to.equal(0)
			expect(#secondTarget:GetChildren()).to.equal(1)

			local secondChild = secondTarget.ChildValue
			expect(secondChild.Value).to.equal(2)

			reconciler.unmountVirtualNode(node)

			expect(#firstTarget:GetChildren()).to.equal(0)
			expect(#secondTarget:GetChildren()).to.equal(0)
		end)
	end)

	describe("Fragments", function()
		it("should parent the fragment's elements into the fragment's parent", function()
			local hostParent = Instance.new("Folder")

			local fragment = createFragment({
				key = createElement("IntValue", {
					Value = 1,
				}),
				key2 = createElement("IntValue", {
					Value = 2,
				}),
			})

			local node = reconciler.mountVirtualNode(fragment, hostParent, "test")

			expect(hostParent:FindFirstChild("key")).to.be.ok()
			expect(hostParent.key.ClassName).to.equal("IntValue")
			expect(hostParent.key.Value).to.equal(1)

			expect(hostParent:FindFirstChild("key2")).to.be.ok()
			expect(hostParent.key2.ClassName).to.equal("IntValue")
			expect(hostParent.key2.Value).to.equal(2)

			reconciler.unmountVirtualNode(node)

			expect(#hostParent:GetChildren()).to.equal(0)
		end)

		it("should allow sibling fragment to have common keys", function()
			local hostParent = Instance.new("Folder")
			local hostKey = "Test"

			local function parent(_props)
				return createElement("IntValue", {}, {
					fragmentA = createFragment({
						key = createElement("StringValue", {
							Value = "A",
						}),
						key2 = createElement("StringValue", {
							Value = "B",
						}),
					}),
					fragmentB = createFragment({
						key = createElement("StringValue", {
							Value = "C",
						}),
						key2 = createElement("StringValue", {
							Value = "D",
						}),
					}),
				})
			end

			local node = reconciler.mountVirtualNode(createElement(parent), hostParent, hostKey)
			local parentChildren = hostParent[hostKey]:GetChildren()

			expect(#parentChildren).to.equal(4)

			local childValues = {}

			for _, child in pairs(parentChildren) do
				expect(child.ClassName).to.equal("StringValue")
				childValues[child.Value] = 1 + (childValues[child.Value] or 0)
			end

			-- check if the StringValues have not collided
			expect(childValues.A).to.equal(1)
			expect(childValues.B).to.equal(1)
			expect(childValues.C).to.equal(1)
			expect(childValues.D).to.equal(1)

			reconciler.unmountVirtualNode(node)

			expect(#hostParent:GetChildren()).to.equal(0)
		end)

		it("should render nested fragments", function()
			local hostParent = Instance.new("Folder")

			local fragment = createFragment({
				key = createFragment({
					TheValue = createElement("IntValue", {
						Value = 1,
					}),
					TheOtherValue = createElement("IntValue", {
						Value = 2,
					}),
				}),
			})

			local node = reconciler.mountVirtualNode(fragment, hostParent, "Test")

			expect(hostParent:FindFirstChild("TheValue")).to.be.ok()
			expect(hostParent.TheValue.ClassName).to.equal("IntValue")
			expect(hostParent.TheValue.Value).to.equal(1)

			expect(hostParent:FindFirstChild("TheOtherValue")).to.be.ok()
			expect(hostParent.TheOtherValue.ClassName).to.equal("IntValue")
			expect(hostParent.TheOtherValue.Value).to.equal(2)

			reconciler.unmountVirtualNode(node)

			expect(#hostParent:GetChildren()).to.equal(0)
		end)

		it("should not add any instances if the fragment is empty", function()
			local hostParent = Instance.new("Folder")

			local node = reconciler.mountVirtualNode(createFragment({}), hostParent, "test")

			expect(#hostParent:GetChildren()).to.equal(0)

			reconciler.unmountVirtualNode(node)

			expect(#hostParent:GetChildren()).to.equal(0)
		end)
	end)

	describe("Context", function()
		it("should pass context values through Roblox host nodes", function()
			local Consumer = Component:extend("Consumer")

			local capturedContext
			function Consumer:init()
				capturedContext = {
					hello = self:__getContext("hello"),
				}
			end

			function Consumer:render() end

			local element = createElement("Folder", nil, {
				Consumer = createElement(Consumer),
			})
			local hostParent = nil
			local hostKey = "Context Test"
			local context = {
				hello = "world",
			}
			local node = reconciler.mountVirtualNode(element, hostParent, hostKey, context)

			expect(capturedContext).never.to.equal(context)
			assertDeepEqual(capturedContext, context)

			reconciler.unmountVirtualNode(node)
		end)

		it("should pass context values through portal nodes", function()
			local target = Instance.new("Folder")

			local Provider = Component:extend("Provider")

			function Provider:init()
				self:__addContext("foo", "bar")
			end

			function Provider:render()
				return createElement("Folder", nil, self.props[Children])
			end

			local Consumer = Component:extend("Consumer")

			local capturedContext
			function Consumer:init()
				capturedContext = {
					foo = self:__getContext("foo"),
				}
			end

			function Consumer:render()
				return nil
			end

			local element = createElement(Provider, nil, {
				Portal = createElement(Portal, {
					target = target,
				}, {
					Consumer = createElement(Consumer),
				}),
			})
			local hostParent = nil
			local hostKey = "Some Key"
			reconciler.mountVirtualNode(element, hostParent, hostKey)

			assertDeepEqual(capturedContext, {
				foo = "bar",
			})
		end)
	end)

	describe("Legacy context", function()
		it("should pass context values through Roblox host nodes", function()
			local Consumer = Component:extend("Consumer")

			local capturedContext
			function Consumer:init()
				capturedContext = self._context
			end

			function Consumer:render() end

			local element = createElement("Folder", nil, {
				Consumer = createElement(Consumer),
			})
			local hostParent = nil
			local hostKey = "Context Test"
			local context = {
				hello = "world",
			}
			local node = reconciler.mountVirtualNode(element, hostParent, hostKey, nil, context)

			expect(capturedContext).never.to.equal(context)
			assertDeepEqual(capturedContext, context)

			reconciler.unmountVirtualNode(node)
		end)

		it("should pass context values through portal nodes", function()
			local target = Instance.new("Folder")

			local Provider = Component:extend("Provider")

			function Provider:init()
				self._context.foo = "bar"
			end

			function Provider:render()
				return createElement("Folder", nil, self.props[Children])
			end

			local Consumer = Component:extend("Consumer")

			local capturedContext
			function Consumer:init()
				capturedContext = self._context
			end

			function Consumer:render()
				return nil
			end

			local element = createElement(Provider, nil, {
				Portal = createElement(Portal, {
					target = target,
				}, {
					Consumer = createElement(Consumer),
				}),
			})
			local hostParent = nil
			local hostKey = "Some Key"
			reconciler.mountVirtualNode(element, hostParent, hostKey)

			assertDeepEqual(capturedContext, {
				foo = "bar",
			})
		end)
	end)

	describe("Integration Tests", function()
		local temporaryParent = nil
		beforeEach(function()
			temporaryParent = Instance.new("Folder")
			temporaryParent.Parent = ReplicatedStorage
		end)

		afterEach(function()
			temporaryParent:Destroy()
			temporaryParent = nil
		end)

		it("should not allow re-entrancy in updateChildren", function()
			local ChildComponent = Component:extend("ChildComponent")

			function ChildComponent:init()
				self:setState({
					firstTime = true,
				})
			end

			local childCoroutine

			function ChildComponent:render()
				if self.state.firstTime then
					return createElement("Frame")
				end

				return createElement("TextLabel")
			end

			function ChildComponent:didMount()
				childCoroutine = coroutine.create(function()
					self:setState({
						firstTime = false,
					})
				end)
			end

			local ParentComponent = Component:extend("ParentComponent")

			function ParentComponent:init()
				self:setState({
					count = 1,
				})

				self.childAdded = function()
					self:setState({
						count = self.state.count + 1,
					})
				end
			end

			function ParentComponent:render()
				return createElement("Frame", {
					[Event.ChildAdded] = self.childAdded,
				}, {
					ChildComponent = createElement(ChildComponent, {
						count = self.state.count,
					}),
				})
			end

			local parent = Instance.new("ScreenGui")
			parent.Parent = temporaryParent

			local tree = createElement(ParentComponent)

			local hostKey = "Some Key"
			local instance = reconciler.mountVirtualNode(tree, parent, hostKey)

			coroutine.resume(childCoroutine)

			expect(#parent:GetChildren()).to.equal(1)

			local frame = parent:GetChildren()[1]

			expect(#frame:GetChildren()).to.equal(1)

			reconciler.unmountVirtualNode(instance)
		end)

		it("should not allow re-entrancy in updateChildren even with callbacks", function()
			local LowestComponent = Component:extend("LowestComponent")

			function LowestComponent:render()
				return createElement("Frame")
			end

			function LowestComponent:didMount()
				self.props.onDidMountCallback()
			end

			local ChildComponent = Component:extend("ChildComponent")

			function ChildComponent:init()
				self:setState({
					firstTime = true,
				})
			end

			local childCoroutine

			function ChildComponent:render()
				if self.state.firstTime then
					return createElement("Frame")
				end

				return createElement(LowestComponent, {
					onDidMountCallback = self.props.onDidMountCallback,
				})
			end

			function ChildComponent:didMount()
				childCoroutine = coroutine.create(function()
					self:setState({
						firstTime = false,
					})
				end)
			end

			local ParentComponent = Component:extend("ParentComponent")

			local didMountCallbackCalled = 0

			function ParentComponent:init()
				self:setState({
					count = 1,
				})

				self.onDidMountCallback = function()
					didMountCallbackCalled = didMountCallbackCalled + 1
					if self.state.count < 5 then
						self:setState({
							count = self.state.count + 1,
						})
					end
				end
			end

			function ParentComponent:render()
				return createElement("Frame", {}, {
					ChildComponent = createElement(ChildComponent, {
						count = self.state.count,
						onDidMountCallback = self.onDidMountCallback,
					}),
				})
			end

			local parent = Instance.new("ScreenGui")
			parent.Parent = temporaryParent

			local tree = createElement(ParentComponent)

			local hostKey = "Some Key"
			local instance = reconciler.mountVirtualNode(tree, parent, hostKey)

			coroutine.resume(childCoroutine)

			expect(#parent:GetChildren()).to.equal(1)

			local frame = parent:GetChildren()[1]

			expect(#frame:GetChildren()).to.equal(1)

			-- In an ideal world, the didMount callback would probably be called only once. Since it is called by two different
			-- LowestComponent instantiations 2 is also acceptable though.
			expect(didMountCallbackCalled <= 2).to.equal(true)

			reconciler.unmountVirtualNode(instance)
		end)

		it("should never call unmount twice in the case of update children re-rentrancy", function()
			local unmountCounts = {}

			local function addUnmount(id)
				unmountCounts[id] = unmountCounts[id] + 1
			end

			local function addInit(id)
				unmountCounts[id] = 0
			end

			local LowestComponent = Component:extend("LowestComponent")
			function LowestComponent:init()
				addInit(tostring(self))
			end

			function LowestComponent:render()
				return createElement("Frame")
			end

			function LowestComponent:didMount()
				self.props.onDidMountCallback()
			end

			function LowestComponent:willUnmount()
				addUnmount(tostring(self))
			end

			local FirstComponent = Component:extend("FirstComponent")
			function FirstComponent:init()
				addInit(tostring(self))
			end

			function FirstComponent:render()
				return createElement("TextLabel")
			end

			function FirstComponent:willUnmount()
				addUnmount(tostring(self))
			end

			local ChildComponent = Component:extend("ChildComponent")

			function ChildComponent:init()
				addInit(tostring(self))

				self:setState({
					firstTime = true,
				})
			end

			local childCoroutine

			function ChildComponent:render()
				if self.state.firstTime then
					return createElement(FirstComponent)
				end

				return createElement(LowestComponent, {
					onDidMountCallback = self.props.onDidMountCallback,
				})
			end

			function ChildComponent:didMount()
				childCoroutine = coroutine.create(function()
					self:setState({
						firstTime = false,
					})
				end)
			end

			function ChildComponent:willUnmount()
				addUnmount(tostring(self))
			end

			local ParentComponent = Component:extend("ParentComponent")

			local didMountCallbackCalled = 0

			function ParentComponent:init()
				self:setState({
					count = 1,
				})

				self.onDidMountCallback = function()
					didMountCallbackCalled = didMountCallbackCalled + 1
					if self.state.count < 5 then
						self:setState({
							count = self.state.count + 1,
						})
					end
				end
			end

			function ParentComponent:render()
				return createElement("Frame", {}, {
					ChildComponent = createElement(ChildComponent, {
						count = self.state.count,
						onDidMountCallback = self.onDidMountCallback,
					}),
				})
			end

			local parent = Instance.new("ScreenGui")
			parent.Parent = temporaryParent

			local tree = createElement(ParentComponent)

			local hostKey = "Some Key"
			local instance = reconciler.mountVirtualNode(tree, parent, hostKey)

			coroutine.resume(childCoroutine)

			expect(#parent:GetChildren()).to.equal(1)

			local frame = parent:GetChildren()[1]

			expect(#frame:GetChildren()).to.equal(1)

			-- In an ideal world, the didMount callback would probably be called only once. Since it is called by two different
			-- LowestComponent instantiations 2 is also acceptable though.
			expect(didMountCallbackCalled <= 2).to.equal(true)

			reconciler.unmountVirtualNode(instance)

			for _, value in pairs(unmountCounts) do
				expect(value).to.equal(1)
			end
		end)

		it("should never unmount a node unnecesarily in the case of re-rentry", function()
			local LowestComponent = Component:extend("LowestComponent")
			function LowestComponent:render()
				return createElement("Frame")
			end

			function LowestComponent:didUpdate(prevProps, _prevState)
				if prevProps.firstTime and not self.props.firstTime then
					self.props.onChangedCallback()
				end
			end

			local ChildComponent = Component:extend("ChildComponent")

			function ChildComponent:init()
				self:setState({
					firstTime = true,
				})
			end

			local childCoroutine

			function ChildComponent:render()
				return createElement(LowestComponent, {
					firstTime = self.state.firstTime,
					onChangedCallback = self.props.onChangedCallback,
				})
			end

			function ChildComponent:didMount()
				childCoroutine = coroutine.create(function()
					self:setState({
						firstTime = false,
					})
				end)
			end

			local ParentComponent = Component:extend("ParentComponent")

			local onChangedCallbackCalled = 0

			function ParentComponent:init()
				self:setState({
					count = 1,
				})

				self.onChangedCallback = function()
					onChangedCallbackCalled = onChangedCallbackCalled + 1
					if self.state.count < 5 then
						self:setState({
							count = self.state.count + 1,
						})
					end
				end
			end

			function ParentComponent:render()
				return createElement("Frame", {}, {
					ChildComponent = createElement(ChildComponent, {
						count = self.state.count,
						onChangedCallback = self.onChangedCallback,
					}),
				})
			end

			local parent = Instance.new("ScreenGui")
			parent.Parent = temporaryParent

			local tree = createElement(ParentComponent)

			local hostKey = "Some Key"
			local instance = reconciler.mountVirtualNode(tree, parent, hostKey)

			coroutine.resume(childCoroutine)

			expect(#parent:GetChildren()).to.equal(1)

			local frame = parent:GetChildren()[1]

			expect(#frame:GetChildren()).to.equal(1)

			expect(onChangedCallbackCalled).to.equal(1)

			reconciler.unmountVirtualNode(instance)
		end)
	end)
end
