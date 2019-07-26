return function()
	local Change = require(script.Parent.PropMarkers.Change)
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local RobloxRenderer = require(script.Parent.RobloxRenderer)
	local snapshot = require(script.Parent.snapshot)

	local robloxReconciler = createReconciler(RobloxRenderer)

	it("should match snapshot of host component with multiple props", function()
		local element = createElement("Frame", {
			BackgroundColor3 = Color3.new(0.1, 0.2, 0.3),
			BackgroundTransparency = 0.205,
			ClipsDescendants = false,
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
				Text = "I am label A"
			}),
			LabelB = createElement(LabelComponent, {
				Text = "I am label B"
			}),
		})

		local tree = robloxReconciler.mountVirtualTree(element)
		local wrapper = tree:getTestRenderOutput()

		snapshot("function-component-children", wrapper):match()
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