return function()
	local RoactRoot = script.Parent.Parent.Parent

	local AnonymousFunction = require(script.Parent.AnonymousFunction)
	local assertDeepEqual = require(RoactRoot.assertDeepEqual)
	local Change = require(RoactRoot.PropMarkers.Change)
	local Component = require(RoactRoot.Component)
	local createElement = require(RoactRoot.createElement)
	local ElementKind = require(RoactRoot.ElementKind)
	local Event = require(RoactRoot.PropMarkers.Event)
	local shallow = require(RoactRoot.shallow)

	local SnapshotData = require(script.Parent.SnapshotData)

	describe("type", function()
		describe("host elements", function()
			it("should contain the host kind", function()
				local wrapper = shallow(createElement("Frame"))

				local result = SnapshotData.type(wrapper.type)

				expect(result.kind).to.equal(ElementKind.Host)
			end)

			it("should contain the class name", function()
				local className = "Frame"
				local wrapper = shallow(createElement(className))

				local result = SnapshotData.type(wrapper.type)

				expect(result.className).to.equal(className)
			end)
		end)

		describe("function elements", function()
			local function SomeComponent()
				return nil
			end

			it("should contain the host kind", function()
				local wrapper = shallow(createElement(SomeComponent))

				local result = SnapshotData.type(wrapper.type)

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

				local result = SnapshotData.type(wrapper.type)

				expect(result.kind).to.equal(ElementKind.Stateful)
			end)

			it("should contain the component name", function()
				local wrapper = shallow(createElement(SomeComponent))

				local result = SnapshotData.type(wrapper.type)

				expect(result.componentName).to.equal(componentName)
			end)
		end)
	end)

	describe("propValue", function()
		it("should return the same value", function()
			local propValues = {7, "hello", Enum.SortOrder.LayoutOrder}

			for i=1, #propValues do
				local prop = propValues[i]
				local result = SnapshotData.propValue(prop)

				expect(result).to.equal(prop)
			end
		end)

		it("should return the AnonymousFunction symbol when given a function", function()
			local result = SnapshotData.propValue(function() end)

			expect(result).to.equal(AnonymousFunction)
		end)
	end)

	describe("props", function()
		it("should keep props with string keys", function()
			local props = {
				image = "hello",
				text = "never",
			}

			local result = SnapshotData.props(props)

			assertDeepEqual(result, props)
		end)

		it("should map Roact.Event to AnonymousFunction", function()
			local props = {
				[Event.Activated] = function() end,
			}

			local result = SnapshotData.props(props)

			assertDeepEqual(result, {
				[Event.Activated] = AnonymousFunction,
			})
		end)

		it("should map Roact.Change to AnonymousFunction", function()
			local props = {
				[Change.Position] = function() end,
			}

			local result = SnapshotData.props(props)

			assertDeepEqual(result, {
				[Change.Position] = AnonymousFunction,
			})
		end)

		it("should throw when the key is a table", function()
			local function shouldThrow()
				SnapshotData.props({
					[{}] = "invalid",
				})
			end

			expect(shouldThrow).to.throw()
		end)
	end)

	describe("wrapper", function()
		it("should have the host key", function()
			local hostKey = "SomeKey"
			local wrapper = shallow(createElement("Frame"))
			wrapper.hostKey = hostKey

			local result = SnapshotData.wrapper(wrapper)

			expect(result.hostKey).to.equal(hostKey)
		end)

		it("should contain the element type", function()
			local wrapper = shallow(createElement("Frame"))

			local result = SnapshotData.wrapper(wrapper)

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
				[Change.Size] = AnonymousFunction,
			}

			local wrapper = shallow(createElement("Frame", props))

			local result = SnapshotData.wrapper(wrapper)

			expect(result.props).to.be.ok()
			assertDeepEqual(result.props, expectProps)
		end)

		it("should contain the element children", function()
			local wrapper = shallow(createElement("Frame", {}, {
				Child = createElement("TextLabel"),
			}))

			local result = SnapshotData.wrapper(wrapper)

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

			local result = SnapshotData.wrapper(wrapper)

			expect(result.children).to.be.ok()
			expect(#result.children).to.equal(2)
			expect(result.children[1].hostKey).to.equal("Child")
			expect(result.children[2].hostKey).to.equal("Label")
		end)
	end)
end