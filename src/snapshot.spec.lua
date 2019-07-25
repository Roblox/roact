return function()
	local Change = require(script.Parent.PropMarkers.Change)
	local createElement = require(script.Parent.createElement)
	local createReconciler = require(script.Parent.createReconciler)
	local RobloxRenderer = require(script.Parent.RobloxRenderer)
	local snapshot = require(script.Parent.snapshot)

	local robloxReconciler = createReconciler(RobloxRenderer)

	it("should match previous snapshot format of host component", function()
		local element = createElement("Frame", {
			BackgroundTransparency = 0.205,
			Visible = true,
			[Change.AbsoluteSize] = function() end,
		})

		local tree = robloxReconciler.mountVirtualTree(element)
		local wrapper = tree:getTestRenderOutput()

		snapshot("host-frame-props", wrapper):match()
	end)

	it("should match previous snapshot format of function component", function()
		local function ChildComponent(props)
			return createElement("TextLabel", props)
		end

		local element = createElement("Frame", {}, {
			LabelA = createElement(ChildComponent, {
				Text = "I am label A"
			}),
			LabelB = createElement(ChildComponent, {
				Text = "I am label B"
			}),
		})

		local tree = robloxReconciler.mountVirtualTree(element)
		local wrapper = tree:getTestRenderOutput()

		snapshot("function-component", wrapper):match()
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