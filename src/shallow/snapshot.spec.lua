return function()
	local RoactRoot = script.Parent.Parent

	local Change = require(RoactRoot.PropMarkers.Change)
	local Component = require(RoactRoot.Component)
	local createElement = require(RoactRoot.createElement)
	local createReconciler = require(RoactRoot.createReconciler)
	local Event = require(RoactRoot.PropMarkers.Event)
	local RobloxRenderer = require(RoactRoot.RobloxRenderer)
	local snapshot = require(script.Parent.snapshot)

	local robloxReconciler = createReconciler(RobloxRenderer)

	it("should match snapshot of host component with multiple props", function()
		local element = createElement("Frame", {
			AnchorPoint = Vector2.new(0, 0.5),
			BackgroundColor3 = Color3.new(0.1, 0.2, 0.3),
			BackgroundTransparency = 0.205,
			ClipsDescendants = false,
			Size = UDim2.new(0.5, 0, 0.4, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeXY,
			Visible = true,
			ZIndex = 5,
		})

		local tree = robloxReconciler.mountVirtualTree(element)
		local wrapper = tree:getTestRenderOutput()

		snapshot("host-frame-with-multiple-props", wrapper):match()
	end)

	it("should match snapshot of function component children", function()
		local function LabelComponent(props)
			return createElement("TextLabel", props)
		end

		local element = createElement("Frame", {}, {
			LabelA = createElement(LabelComponent, {
				Text = "I am label A",
			}),
			LabelB = createElement(LabelComponent, {
				Text = "I am label B",
			}),
		})

		local tree = robloxReconciler.mountVirtualTree(element)
		local wrapper = tree:getTestRenderOutput()

		snapshot("function-component-children", wrapper):match()
	end)

	it("should match snapshot of stateful component", function()
		local StatefulComponent = Component:extend("CoolComponent")

		function StatefulComponent:render()
			return createElement("TextLabel")
		end

		local element = createElement("Frame", {}, {
			Child = createElement(StatefulComponent, {
				label = {
					Text = "foo",
				},
			}),
		})

		local tree = robloxReconciler.mountVirtualTree(element)
		local wrapper = tree:getTestRenderOutput()

		snapshot("stateful-component-children", wrapper):match()
	end)

	it("should match snapshot with event props", function()
		local function emptyFunction()
		end

		local element = createElement("TextButton", {
			[Change.AbsoluteSize] = emptyFunction,
			[Change.Visible] = emptyFunction,
			[Event.Activated] = emptyFunction,
			[Event.MouseButton1Click] = emptyFunction,
		})

		local tree = robloxReconciler.mountVirtualTree(element)
		local wrapper = tree:getTestRenderOutput()

		snapshot("component-with-event-props", wrapper):match()
	end)

	it("should throw if the identifier contains invalid characters", function()
		local invalidCharacters = {"\\", "/", "?"}

		for i=1, #invalidCharacters do
			local function shouldThrow()
				snapshot("id" .. invalidCharacters[i], {})
			end

			expect(shouldThrow).to.throw()
		end
	end)
end