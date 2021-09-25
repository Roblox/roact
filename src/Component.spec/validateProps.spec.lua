return function()
	local createElement = require(script.Parent.Parent.createElement)
	local createReconciler = require(script.Parent.Parent.createReconciler)
	local createSpy = require(script.Parent.Parent.createSpy)
	local NoopRenderer = require(script.Parent.Parent.NoopRenderer)
	local GlobalConfig = require(script.Parent.Parent.GlobalConfig)

	local Component = require(script.Parent.Parent.Component)

	local noopReconciler = createReconciler(NoopRenderer)

	it("should be invoked when mounted", function()
		local config = {
			propValidation = true,
		}

		GlobalConfig.scoped(config, function()
			local MyComponent = Component:extend("MyComponent")

			local validatePropsSpy = createSpy(function()
				return true
			end)

			MyComponent.validateProps = validatePropsSpy.value

			function MyComponent:render()
				return nil
			end

			local element = createElement(MyComponent)
			local hostParent = nil
			local key = "Test"

			noopReconciler.mountVirtualNode(element, hostParent, key)
			expect(validatePropsSpy.callCount).to.equal(1)
		end)
	end)

	it("should be invoked when props change", function()
		local config = {
			propValidation = true,
		}

		GlobalConfig.scoped(config, function()
			local MyComponent = Component:extend("MyComponent")

			local validatePropsSpy = createSpy(function()
				return true
			end)

			MyComponent.validateProps = validatePropsSpy.value

			function MyComponent:render()
				return nil
			end

			local element = createElement(MyComponent, { a = 1 })
			local hostParent = nil
			local key = "Test"

			local node = noopReconciler.mountVirtualNode(element, hostParent, key)
			expect(validatePropsSpy.callCount).to.equal(1)
			validatePropsSpy:assertCalledWithDeepEqual({
				a = 1,
			})

			local newElement = createElement(MyComponent, { a = 2 })
			noopReconciler.updateVirtualNode(node, newElement)
			expect(validatePropsSpy.callCount).to.equal(2)
			validatePropsSpy:assertCalledWithDeepEqual({
				a = 2,
			})
		end)
	end)

	it("should not be invoked when state changes", function()
		local config = {
			propValidation = true,
		}

		GlobalConfig.scoped(config, function()
			local MyComponent = Component:extend("MyComponent")

			local setStateCallback = nil
			local validatePropsSpy = createSpy(function()
				return true
			end)

			MyComponent.validateProps = validatePropsSpy.value

			function MyComponent:init()
				setStateCallback = function(newState)
					self:setState(newState)
				end
			end

			function MyComponent:render()
				return nil
			end

			local element = createElement(MyComponent, { a = 1 })
			local hostParent = nil
			local key = "Test"

			noopReconciler.mountVirtualNode(element, hostParent, key)
			expect(validatePropsSpy.callCount).to.equal(1)
			validatePropsSpy:assertCalledWithDeepEqual({
				a = 1,
			})

			setStateCallback({
				b = 1,
			})

			expect(validatePropsSpy.callCount).to.equal(1)
		end)
	end)

	it("should throw if validateProps is not a function", function()
		local config = {
			propValidation = true,
		}

		GlobalConfig.scoped(config, function()
			local MyComponent = Component:extend("MyComponent")
			MyComponent.validateProps = 1

			function MyComponent:render()
				return nil
			end

			local element = createElement(MyComponent)
			local hostParent = nil
			local key = "Test"

			expect(function()
				noopReconciler.mountVirtualNode(element, hostParent, key)
			end).to.throw()
		end)
	end)

	it("should throw if validateProps returns false", function()
		local config = {
			propValidation = true,
		}

		GlobalConfig.scoped(config, function()
			local MyComponent = Component:extend("MyComponent")
			MyComponent.validateProps = function()
				return false
			end

			function MyComponent:render()
				return nil
			end

			local element = createElement(MyComponent)
			local hostParent = nil
			local key = "Test"

			expect(function()
				noopReconciler.mountVirtualNode(element, hostParent, key)
			end).to.throw()
		end)
	end)

	it("should include the component name in the error message", function()
		local config = {
			propValidation = true,
		}

		GlobalConfig.scoped(config, function()
			local MyComponent = Component:extend("MyComponent")
			MyComponent.validateProps = function()
				return false
			end

			function MyComponent:render()
				return nil
			end

			local element = createElement(MyComponent)
			local hostParent = nil
			local key = "Test"

			local success, error = pcall(function()
				noopReconciler.mountVirtualNode(element, hostParent, key)
			end)

			expect(success).to.equal(false)
			local startIndex = error:find("MyComponent")
			expect(startIndex).to.be.ok()
		end)
	end)

	it("should be invoked after defaultProps are applied", function()
		local config = {
			propValidation = true,
		}

		GlobalConfig.scoped(config, function()
			local MyComponent = Component:extend("MyComponent")

			local validatePropsSpy = createSpy(function()
				return true
			end)

			MyComponent.validateProps = validatePropsSpy.value

			function MyComponent:render()
				return nil
			end

			MyComponent.defaultProps = {
				b = 2,
			}

			local element = createElement(MyComponent, { a = 1 })
			local hostParent = nil
			local key = "Test"

			local node = noopReconciler.mountVirtualNode(element, hostParent, key)
			expect(validatePropsSpy.callCount).to.equal(1)
			validatePropsSpy:assertCalledWithDeepEqual({
				a = 1,
				b = 2,
			})

			local newElement = createElement(MyComponent, { a = 2 })
			noopReconciler.updateVirtualNode(node, newElement)
			expect(validatePropsSpy.callCount).to.equal(2)
			validatePropsSpy:assertCalledWithDeepEqual({
				a = 2,
				b = 2,
			})
		end)
	end)

	it("should not be invoked if the flag is off", function()
		local config = {
			propValidation = false,
		}

		GlobalConfig.scoped(config, function()
			local MyComponent = Component:extend("MyComponent")

			local validatePropsSpy = createSpy(function()
				return true
			end)

			MyComponent.validateProps = validatePropsSpy.value

			function MyComponent:render()
				return nil
			end

			local element = createElement(MyComponent, { a = 1 })
			local hostParent = nil
			local key = "Test"

			local node = noopReconciler.mountVirtualNode(element, hostParent, key)
			expect(validatePropsSpy.callCount).to.equal(0)

			local newElement = createElement(MyComponent, { a = 2 })
			noopReconciler.updateVirtualNode(node, newElement)
			expect(validatePropsSpy.callCount).to.equal(0)
		end)
	end)
end
