return function()
	local RoactRoot = script.Parent.Parent.Parent.Parent

	local Markers = require(script.Parent.Markers)
	local assertDeepEqual = require(RoactRoot.assertDeepEqual)
	local Binding = require(RoactRoot.Binding)
	local Change = require(RoactRoot.PropMarkers.Change)
	local Component = require(RoactRoot.Component)
	local createElement = require(RoactRoot.createElement)
	local createReconciler = require(RoactRoot.createReconciler)
	local createRef = require(RoactRoot.createRef)
	local ElementKind = require(RoactRoot.ElementKind)
	local Event = require(RoactRoot.PropMarkers.Event)
	local Ref = require(RoactRoot.PropMarkers.Ref)
	local RobloxRenderer = require(RoactRoot.RobloxRenderer)
	local ShallowWrapper = require(script.Parent.Parent.Parent.ShallowWrapper)

	local Snapshot = require(script.Parent.Snapshot)

	local robloxReconciler = createReconciler(RobloxRenderer)

	local function shallow(element, options)
		options = options or {}
		local maxDepth = options.depth or 1
		local hostKey = options.hostKey or "ShallowTree"
		local hostParent = options.hostParent or Instance.new("Folder")

		local virtualNode = robloxReconciler.mountVirtualNode(element, hostParent, hostKey)

		return ShallowWrapper.new(virtualNode, maxDepth)
	end

	describe("type", function()
		describe("host elements", function()
			it("should contain the host kind", function()
				local wrapper = shallow(createElement("Frame"))

				local result = Snapshot.type(wrapper.component)

				expect(result.kind).to.equal(ElementKind.Host)
			end)

			it("should contain the class name", function()
				local className = "Frame"
				local wrapper = shallow(createElement(className))

				local result = Snapshot.type(wrapper.component)

				expect(result.className).to.equal(className)
			end)
		end)

		describe("function elements", function()
			local function SomeComponent()
				return nil
			end

			it("should contain the host kind", function()
				local wrapper = shallow(createElement(SomeComponent))

				local result = Snapshot.type(wrapper.component)

				expect(result.kind).to.equal(ElementKind.Function)
			end)
		end)

		describe("stateful elements", function()
			local componentName = "ComponentName"
			local SomeComponent = Component:extend(componentName)

			function SomeComponent:render()
				return nil
			end

			it("should contain the host kind", function()
				local wrapper = shallow(createElement(SomeComponent))

				local result = Snapshot.type(wrapper.component)

				expect(result.kind).to.equal(ElementKind.Stateful)
			end)

			it("should contain the component name", function()
				local wrapper = shallow(createElement(SomeComponent))

				local result = Snapshot.type(wrapper.component)

				expect(result.componentName).to.equal(componentName)
			end)
		end)
	end)

	describe("signal", function()
		it("should convert signals", function()
			local signalName = "Foo"
			local signalMock = setmetatable({}, {
				__tostring = function()
					return "Signal " .. signalName
				end
			})

			local result = Snapshot.signal(signalMock)

			assertDeepEqual(result, {
				[Markers.Signal] = signalName
			})
		end)
	end)

	describe("propValue", function()
		it("should return the same value for basic types", function()
			local propValues = {7, "hello", Enum.SortOrder.LayoutOrder}

			for i=1, #propValues do
				local prop = propValues[i]
				local result = Snapshot.propValue(prop)

				expect(result).to.equal(prop)
			end
		end)

		it("should return an empty table given an empty table", function()
			local result = Snapshot.propValue({})

			expect(next(result)).never.to.be.ok()
		end)

		it("should serialize a table as a props table", function()
			local key = "some key"
			local value = {
				[key] = "foo",
			}
			local result = Snapshot.propValue(value)

			expect(result[key]).to.equal("foo")
			expect(next(result, key)).never.to.be.ok()
		end)

		it("should return the AnonymousFunction symbol when given a function", function()
			local result = Snapshot.propValue(function() end)

			expect(result).to.equal(Markers.AnonymousFunction)
		end)

		it("should return the Unknown symbol when given an unexpected value", function()
			local result = Snapshot.propValue(nil)

			expect(result).to.equal(Markers.Unknown)
		end)
	end)

	describe("props", function()
		it("should keep props with string keys", function()
			local props = {
				image = "hello",
				text = "never",
			}

			local result = Snapshot.props(props)

			assertDeepEqual(result, props)
		end)

		it("should map Roact.Event to AnonymousFunction", function()
			local props = {
				[Event.Activated] = function() end,
			}

			local result = Snapshot.props(props)

			assertDeepEqual(result, {
				[Event.Activated] = Markers.AnonymousFunction,
			})
		end)

		it("should map Roact.Change to AnonymousFunction", function()
			local props = {
				[Change.Position] = function() end,
			}

			local result = Snapshot.props(props)

			assertDeepEqual(result, {
				[Change.Position] = Markers.AnonymousFunction,
			})
		end)

		it("should map empty refs to the EmptyRef symbol", function()
			local props = {
				[Ref] = createRef(),
			}

			local result = Snapshot.props(props)

			assertDeepEqual(result, {
				[Ref] = Markers.EmptyRef,
			})
		end)

		it("should map refs with value to their symbols", function()
			local instanceClassName = "Folder"
			local ref = createRef()
			Binding.update(ref, Instance.new(instanceClassName))

			local props = {
				[Ref] = ref,
			}

			local result = Snapshot.props(props)

			assertDeepEqual(result, {
				[Ref] = {
					className = instanceClassName,
				},
			})
		end)

		it("should throw when the key is a table", function()
			local function shouldThrow()
				Snapshot.props({
					[{}] = "invalid",
				})
			end

			expect(shouldThrow).to.throw()
		end)
	end)

	describe("child", function()
		it("should have the host key", function()
			local hostKey = "SomeKey"
			local wrapper = shallow(createElement("Frame"))
			wrapper.hostKey = hostKey

			local result = Snapshot.child(wrapper)

			expect(result.hostKey).to.equal(hostKey)
		end)

		it("should contain the element type", function()
			local wrapper = shallow(createElement("Frame"))

			local result = Snapshot.child(wrapper)

			expect(result.type).to.be.ok()
			expect(result.type.kind).to.equal(ElementKind.Host)
			expect(result.type.className).to.equal("Frame")
		end)

		it("should contain the props", function()
			local props = {
				LayoutOrder = 3,
				[Change.Size] = function() end,
			}
			local expectProps = {
				LayoutOrder = 3,
				[Change.Size] = Markers.AnonymousFunction,
			}

			local wrapper = shallow(createElement("Frame", props))

			local result = Snapshot.child(wrapper)

			expect(result.props).to.be.ok()
			assertDeepEqual(result.props, expectProps)
		end)

		it("should contain the element children", function()
			local wrapper = shallow(createElement("Frame", {}, {
				Child = createElement("TextLabel"),
			}))

			local result = Snapshot.child(wrapper)

			expect(result.children).to.be.ok()
			expect(#result.children).to.equal(1)
			local childData = result.children[1]
			expect(childData.type.kind).to.equal(ElementKind.Host)
			expect(childData.type.className).to.equal("TextLabel")
		end)

		it("should sort children by their host key", function()
			local wrapper = shallow(createElement("Frame", {}, {
				Child = createElement("TextLabel"),
				Label = createElement("TextLabel"),
			}))

			local result = Snapshot.child(wrapper)

			expect(result.children).to.be.ok()
			expect(#result.children).to.equal(2)
			expect(result.children[1].hostKey).to.equal("Child")
			expect(result.children[2].hostKey).to.equal("Label")
		end)
	end)

	describe("new", function()
		it("should clear the host key", function()
			local wrapper = shallow(createElement("Frame"))

			local result = Snapshot.new(wrapper)

			expect(result.hostKey).never.to.be.ok()
		end)

		it("should contain the element type", function()
			local wrapper = shallow(createElement("Frame"))

			local result = Snapshot.new(wrapper)

			expect(result.type).to.be.ok()
			expect(result.type.kind).to.equal(ElementKind.Host)
			expect(result.type.className).to.equal("Frame")
		end)

		it("should contain the props", function()
			local props = {
				LayoutOrder = 3,
				[Change.Size] = function() end,
			}
			local expectProps = {
				LayoutOrder = 3,
				[Change.Size] = Markers.AnonymousFunction,
			}

			local wrapper = shallow(createElement("Frame", props))

			local result = Snapshot.new(wrapper)

			expect(result.props).to.be.ok()
			assertDeepEqual(result.props, expectProps)
		end)

		it("should contain the element children", function()
			local wrapper = shallow(createElement("Frame", {}, {
				Child = createElement("TextLabel"),
			}))

			local result = Snapshot.new(wrapper)

			expect(result.children).to.be.ok()
			expect(#result.children).to.equal(1)
			local childData = result.children[1]
			expect(childData.type.kind).to.equal(ElementKind.Host)
			expect(childData.type.className).to.equal("TextLabel")
		end)

		it("should sort children by their host key", function()
			local wrapper = shallow(createElement("Frame", {}, {
				Child = createElement("TextLabel"),
				Label = createElement("TextLabel"),
			}))

			local result = Snapshot.new(wrapper)

			expect(result.children).to.be.ok()
			expect(#result.children).to.equal(2)
			expect(result.children[1].hostKey).to.equal("Child")
			expect(result.children[2].hostKey).to.equal("Label")
		end)
	end)
end