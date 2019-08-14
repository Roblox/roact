return function()
	local RoactRoot = script.Parent.Parent.Parent

	local ElementKind = require(RoactRoot.ElementKind)
	local createElement = require(RoactRoot.createElement)
	local createReconciler = require(RoactRoot.createReconciler)
	local RoactComponent = require(RoactRoot.Component)
	local RobloxRenderer = require(RoactRoot.RobloxRenderer)

	local Constraints = require(script.Parent.Constraints)

	local robloxReconciler = createReconciler(RobloxRenderer)

	local HOST_PARENT = nil
	local HOST_KEY = "ConstraintsTree"

	local function getVirtualNode(element)
		return robloxReconciler.mountVirtualNode(element, HOST_PARENT, HOST_KEY)
	end

	describe("className", function()
		it("should return true when a host virtualNode has the given class name", function()
			local className = "TextLabel"
			local element = createElement(className)

			local virtualNode = getVirtualNode(element)

			local result = Constraints.className(virtualNode, className)

			expect(result).to.equal(true)
		end)

		it("should return false when a host virtualNode does not have the same class name", function()
			local element = createElement("Frame")

			local virtualNode = getVirtualNode(element)

			local result = Constraints.className(virtualNode, "TextLabel")

			expect(result).to.equal(false)
		end)

		it("should return false when not a host virtualNode", function()
			local function Component()
				return createElement("TextLabel")
			end
			local element = createElement(Component)

			local virtualNode = getVirtualNode(element)

			local result = Constraints.className(virtualNode, "TextLabel")

			expect(result).to.equal(false)
		end)
	end)

	describe("component", function()
		it("should return true given a host virtualNode with the same class name", function()
			local className = "TextLabel"
			local element = createElement(className)

			local virtualNode = getVirtualNode(element)

			local result = Constraints.component(virtualNode, className)

			expect(result).to.equal(true)
		end)

		it("should return true given a functional virtualNode function", function()
			local function Component(props)
				return nil
			end

			local element = createElement(Component)
			local virtualNode = getVirtualNode(element)

			local result = Constraints.component(virtualNode, Component)

			expect(result).to.equal(true)
		end)

		it("should return true given a stateful virtualNode component class", function()
			local Component = RoactComponent:extend("Foo")

			function Component:render()
				return nil
			end

			local element = createElement(Component)
			local virtualNode = getVirtualNode(element)

			local result = Constraints.component(virtualNode, Component)

			expect(result).to.equal(true)
		end)

		it("should return false when components kind do not match", function()
			local function Component(props)
				return nil
			end

			local element = createElement(Component)
			local virtualNode = getVirtualNode(element)

			local result = Constraints.component(virtualNode, "TextLabel")

			expect(result).to.equal(false)
		end)
	end)

	describe("props", function()
		it("should return true when the virtualNode satisfies all prop constraints", function()
			local props = {
				Visible = false,
				LayoutOrder = 7,
			}
			local element = createElement("TextLabel", props)
			local virtualNode = getVirtualNode(element)

			local result = Constraints.props(virtualNode, {
				Visible = false,
				LayoutOrder = 7,
			})

			expect(result).to.equal(true)
		end)

		it("should return true if the props are from a subset of the virtualNode props", function()
			local props = {
				Visible = false,
				LayoutOrder = 7,
			}

			local element = createElement("TextLabel", props)
			local virtualNode = getVirtualNode(element)

			local result = Constraints.props(virtualNode, {
				LayoutOrder = 7,
			})

			expect(result).to.equal(true)
		end)

		it("should return false if a subset of the props are different from the given props", function()
			local props = {
				Visible = false,
				LayoutOrder = 1,
			}

			local element = createElement("TextLabel", props)
			local virtualNode = getVirtualNode(element)

			local result = Constraints.props(virtualNode, {
				LayoutOrder = 7,
			})

			expect(result).to.equal(false)
		end)
	end)

	describe("hostKey", function()
		it("should return true when the virtualNode has the same hostKey", function()
			local element = createElement("TextLabel")
			local virtualNode = getVirtualNode(element)

			local result = Constraints.hostKey(virtualNode, HOST_KEY)

			expect(result).to.equal(true)
		end)

		it("should return false when the virtualNode hostKey is different", function()
			local element = createElement("TextLabel")
			local virtualNode = getVirtualNode(element)

			local result = Constraints.hostKey(virtualNode, "foo")

			expect(result).to.equal(false)
		end)
	end)
end