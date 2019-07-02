return function()
	local shallow = require(script.Parent.shallow)

	local ElementKind = require(script.Parent.ElementKind)
	local createElement = require(script.Parent.createElement)
	local createFragment = require(script.Parent.createFragment)
	local RoactComponent = require(script.Parent.Component)

	describe("single host element", function()
		local className = "TextLabel"

		local function Component(props)
			return createElement(className, props)
		end

		it("should have it's type.kind to Host", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result.type.kind).to.equal(ElementKind.Host)
		end)

		it("should have its type.className to given instance class", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result.type.className).to.equal(className)
		end)

		it("children count should be zero", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result:childrenCount()).to.equal(0)
		end)
	end)

	describe("single function element", function()
		local function FunctionComponent(props)
			return createElement("TextLabel")
		end

		local function Component(props)
			return createElement(FunctionComponent, props)
		end

		it("should have its type.kind to Function", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result.type.kind).to.equal(ElementKind.Function)
		end)

		it("should have its type.functionComponent to Function", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result.type.functionComponent).to.equal(FunctionComponent)
		end)
	end)

	describe("single stateful element", function()
		local StatefulComponent = RoactComponent:extend("StatefulComponent")

		function StatefulComponent:render()
			return createElement("TextLabel")
		end

		local function Component(props)
			return createElement(StatefulComponent, props)
		end

		it("should have its type.kind to Stateful", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result.type.kind).to.equal(ElementKind.Stateful)
		end)

		it("should have its type.component to given component class", function()
			local element = createElement(Component)

			local result = shallow(element)

			expect(result.type.component).to.equal(StatefulComponent)
		end)
	end)

	describe("depth", function()
		local unwrappedClassName = "TextLabel"
		local function A(props)
			return createElement(unwrappedClassName)
		end

		local function B(props)
			return createElement(A)
		end

		local function Component(props)
			return createElement(B)
		end

		local function ComponentWithChildren(props)
			return createElement("Frame", {}, {
				ChildA = createElement(A),
				ChildB = createElement(B),
			})
		end

		it("should unwrap function components when depth has not exceeded", function()
			local element = createElement(Component)

			local result = shallow(element, {
				depth = 3,
			})

			expect(result.type.kind).to.equal(ElementKind.Host)
			expect(result.type.className).to.equal(unwrappedClassName)
		end)

		it("should stop unwrapping function components when depth has exceeded", function()
			local element = createElement(Component)

			local result = shallow(element, {
				depth = 2,
			})

			expect(result.type.kind).to.equal(ElementKind.Function)
			expect(result.type.functionComponent).to.equal(A)
		end)

		it("should not unwrap the element when depth is zero", function()
			local element = createElement(Component)

			local result = shallow(element, {
				depth = 0,
			})

			expect(result.type.kind).to.equal(ElementKind.Function)
			expect(result.type.functionComponent).to.equal(Component)
		end)

		it("should not unwrap children when depth is one", function()
			local element = createElement(ComponentWithChildren)

			local result = shallow(element, {
				depth = 1,
			})

			local childA = result:find({
				component = A,
			})
			expect(#childA).to.equal(1)

			local childB = result:find({
				component = B,
			})
			expect(#childB).to.equal(1)
		end)

		it("should unwrap children when depth is two", function()
			local element = createElement(ComponentWithChildren)

			local result = shallow(element, {
				depth = 2,
			})

			local hostChild = result:find({
				component = unwrappedClassName,
			})
			expect(#hostChild).to.equal(1)

			local unwrappedBChild = result:find({
				component = A,
			})
			expect(#unwrappedBChild).to.equal(1)
		end)

		it("should not include any children when depth is zero", function()
			local element = createElement(ComponentWithChildren)

			local result = shallow(element, {
				depth = 0,
			})

			expect(result:childrenCount()).to.equal(0)
		end)

		it("should not include any grand-children when depth is one", function()
			local function ParentComponent()
				return createElement("Folder", {}, {
					Child = createElement(ComponentWithChildren),
				})
			end

			local element = createElement(ParentComponent)

			local result = shallow(element, {
				depth = 1,
			})

			expect(result:childrenCount()).to.equal(1)

			local componentWithChildrenWrapper = result:find({
				component = ComponentWithChildren,
			})[1]
			expect(componentWithChildrenWrapper).to.be.ok()

			expect(componentWithChildrenWrapper:childrenCount()).to.equal(0)
		end)
	end)

	describe("childrenCount", function()
		local childClassName = "TextLabel"

		local function Component(props)
			local children = {}

			for i=1, props.childrenCount do
				children[("Key%d"):format(i)] = createElement(childClassName)
			end

			return createElement("Frame", {}, children)
		end

		it("should return 1 when the element contains only one child element", function()
			local element = createElement(Component, {
				childrenCount = 1,
			})

			local result = shallow(element)

			expect(result:childrenCount()).to.equal(1)
		end)

		it("should return 0 when the element does not contain elements", function()
			local element = createElement(Component, {
				childrenCount = 0,
			})

			local result = shallow(element)

			expect(result:childrenCount()).to.equal(0)
		end)

		it("should count children in a fragment", function()
			local element = createElement("Frame", {}, {
				Frag = createFragment({
					Label = createElement("TextLabel"),
					Button = createElement("TextButton"),
				})
			})

			local result = shallow(element)

			expect(result:childrenCount()).to.equal(2)
		end)

		it("should count children nested in fragments", function()
			local element = createElement("Frame", {}, {
				Frag = createFragment({
					SubFrag = createFragment({
						Frame = createElement("Frame"),
					}),
					Label = createElement("TextLabel"),
					Button = createElement("TextButton"),
				})
			})

			local result = shallow(element)

			expect(result:childrenCount()).to.equal(3)
		end)
	end)

	describe("props", function()
		it("should contains the same props using Host element", function()
			local function Component(props)
				return createElement("Frame", props)
			end

			local props = {
				BackgroundTransparency = 1,
				Visible = false,
			}
			local element = createElement(Component, props)

			local result = shallow(element)

			expect(result.type.kind).to.equal(ElementKind.Host)
			expect(result.props).to.be.ok()

			for key, value in pairs(props) do
				expect(result.props[key]).to.equal(value)
			end
			for key, value in pairs(result.props) do
				expect(props[key]).to.equal(value)
			end
		end)

		it("should have the same props using function element", function()
			local function ChildComponent(props)
				return createElement("Frame", props)
			end

			local function Component(props)
				return createElement(ChildComponent, props)
			end

			local props = {
				BackgroundTransparency = 1,
				Visible = false,
			}
			local element = createElement(Component, props)

			local result = shallow(element)

			expect(result.type.kind).to.equal(ElementKind.Function)
			expect(result.props).to.be.ok()

			for key, value in pairs(props) do
				expect(result.props[key]).to.equal(value)
			end
			for key, value in pairs(result.props) do
				expect(props[key]).to.equal(value)
			end
		end)

		it("should not have the children property", function()
			local function ComponentWithChildren(props)
				return createElement("Frame", props, {
					Key = createElement("TextLabel"),
				})
			end

			local props = {
				BackgroundTransparency = 1,
				Visible = false,
			}
			local element = createElement(ComponentWithChildren, props)

			local result = shallow(element)

			expect(result.props).to.be.ok()

			for key, value in pairs(props) do
				expect(result.props[key]).to.equal(value)
			end
			for key, value in pairs(result.props) do
				expect(props[key]).to.equal(value)
			end
		end)

		it("should have the inherited props", function()
			local function Component(props)
				local frameProps = {
					LayoutOrder = 7,
				}
				for key, value in pairs(props) do
					frameProps[key] = value
				end

				return createElement("Frame", frameProps)
			end

			local element = createElement(Component, {
				BackgroundTransparency = 1,
				Visible = false,
			})

			local result = shallow(element)

			expect(result.props).to.be.ok()

			local expectProps = {
				BackgroundTransparency = 1,
				Visible = false,
				LayoutOrder = 7,
			}

			for key, value in pairs(expectProps) do
				expect(result.props[key]).to.equal(value)
			end
			for key, value in pairs(result.props) do
				expect(expectProps[key]).to.equal(value)
			end
		end)
	end)

	describe("find children", function()
		local function Component(props)
			return createElement("Frame", {}, props.children)
		end

		describe("kind constraint", function()
			it("should find the child element", function()
				local childClassName = "TextLabel"
				local element = createElement(Component, {
					children = {
						Child = createElement(childClassName),
					},
				})

				local result = shallow(element)

				local constraints = {
					kind = ElementKind.Host,
				}
				local children = result:find(constraints)

				expect(#children).to.equal(1)

				local child = children[1]

				expect(child.type.kind).to.equal(ElementKind.Host)
				expect(child.type.className).to.equal(childClassName)
			end)

			it("should return an empty list when no children is found", function()
				local element = createElement(Component, {
					children = {
						Child = createElement("TextLabel"),
					},
				})

				local result = shallow(element)

				local constraints = {
					kind = ElementKind.Function,
				}
				local children = result:find(constraints)

				expect(next(children)).never.to.be.ok()
			end)
		end)

		describe("className constraint", function()
			it("should find the child element", function()
				local childClassName = "TextLabel"
				local element = createElement(Component, {
					children = {
						Child = createElement(childClassName),
					},
				})

				local result = shallow(element)

				local constraints = {
					className = childClassName,
				}
				local children = result:find(constraints)

				expect(#children).to.equal(1)

				local child = children[1]

				expect(child.type.kind).to.equal(ElementKind.Host)
				expect(child.type.className).to.equal(childClassName)
			end)

			it("should return an empty list when no children is found", function()
				local element = createElement(Component, {
					children = {
						Child = createElement("TextLabel"),
					},
				})

				local result = shallow(element)

				local constraints = {
					className = "Frame",
				}
				local children = result:find(constraints)

				expect(next(children)).never.to.be.ok()
			end)
		end)

		describe("component constraint", function()
			it("should find the child element by it's class name", function()
				local childClassName = "TextLabel"
				local element = createElement(Component, {
					children = {
						Child = createElement(childClassName),
					},
				})

				local result = shallow(element)

				local constraints = {
					component = childClassName,
				}
				local children = result:find(constraints)

				expect(#children).to.equal(1)

				local child = children[1]

				expect(child.type.kind).to.equal(ElementKind.Host)
				expect(child.type.className).to.equal(childClassName)
			end)

			it("should find the child element by it's function", function()
				local function ChildComponent(props)
					return nil
				end

				local element = createElement(Component, {
					children = {
						Child = createElement(ChildComponent),
					},
				})

				local result = shallow(element)

				local constraints = {
					component = ChildComponent,
				}
				local children = result:find(constraints)

				expect(#children).to.equal(1)

				local child = children[1]

				expect(child.type.kind).to.equal(ElementKind.Function)
				expect(child.type.functionComponent).to.equal(ChildComponent)
			end)

			it("should find the child element by it's component class", function()
				local ChildComponent = RoactComponent:extend("ChildComponent")

				function ChildComponent:render()
					return createElement("TextLabel")
				end

				local element = createElement(Component, {
					children = {
						Child = createElement(ChildComponent),
					},
				})

				local result = shallow(element)

				local constraints = {
					component = ChildComponent,
				}
				local children = result:find(constraints)

				expect(#children).to.equal(1)

				local child = children[1]

				expect(child.type.kind).to.equal(ElementKind.Stateful)
				expect(child.type.component).to.equal(ChildComponent)
			end)

			it("should return an empty list when no children is found", function()
				local element = createElement(Component, {
					children = {
						Child = createElement("TextLabel"),
					},
				})

				local result = shallow(element)

				local constraints = {
					component = "Frame",
				}
				local children = result:find(constraints)

				expect(next(children)).never.to.be.ok()
			end)
		end)

		describe("props constraint", function()
			it("should find the child element that satisfies all prop constraints", function()
				local childClassName = "Frame"
				local props = {
					Visible = false,
					LayoutOrder = 7,
				}
				local element = createElement(Component, {
					children = {
						Child = createElement(childClassName, props),
					},
				})

				local result = shallow(element)

				local constraints = {
					props = {
						Visible = false,
						LayoutOrder = 7,
					},
				}
				local children = result:find(constraints)

				expect(#children).to.equal(1)

				local child = children[1]

				expect(child.type.kind).to.equal(ElementKind.Host)
				expect(child.type.className).to.equal(childClassName)
			end)

			it("should find the child element from a subset of props", function()
				local childClassName = "Frame"
				local props = {
					Visible = false,
					LayoutOrder = 7,
				}
				local element = createElement(Component, {
					children = {
						Child = createElement(childClassName, props),
					},
				})

				local result = shallow(element)

				local constraints = {
					props = {
						LayoutOrder = 7,
					},
				}
				local children = result:find(constraints)

				expect(#children).to.equal(1)

				local child = children[1]

				expect(child.type.kind).to.equal(ElementKind.Host)
				expect(child.type.className).to.equal(childClassName)
			end)

			it("should return an empty list when no children is found", function()
				local element = createElement(Component, {
					children = {
						Child = createElement("TextLabel", {
							Visible = false,
							LayoutOrder = 7,
						}),
					},
				})

				local result = shallow(element)

				local constraints = {
					props = {
						Visible = false,
						LayoutOrder = 4,
					},
				}
				local children = result:find(constraints)

				expect(next(children)).never.to.be.ok()
			end)
		end)

		it("should throw if the constraint does not exist", function()
			local element = createElement("Frame")

			local result = shallow(element)

			local function findWithInvalidConstraint()
				result:find({
					nothing = false,
				})
			end

			expect(findWithInvalidConstraint).to.throw()
		end)

		it("should return children that matches all contraints", function()
			local function ComponentWithChildren()
				return createElement("Frame", {}, {
					ChildA = createElement("TextLabel", {
						Visible = false,
					}),
					ChildB = createElement("TextButton", {
						Visible = false,
					}),
				})
			end

			local element = createElement(ComponentWithChildren)

			local result = shallow(element)

			local children = result:find({
				className = "TextLabel",
				props = {
					Visible = false,
				},
			})

			expect(#children).to.equal(1)
		end)

		it("should return children from fragments", function()
			local childClassName = "TextLabel"

			local function ComponentWithFragment()
				return createElement("Frame", {}, {
					Fragment = createFragment({
						Child = createElement(childClassName),
					}),
				})
			end

			local element = createElement(ComponentWithFragment)

			local result = shallow(element)

			local children = result:find({
				className = childClassName
			})

			expect(#children).to.equal(1)
		end)

		it("should return children from nested fragments", function()
			local childClassName = "TextLabel"

			local function ComponentWithFragment()
				return createElement("Frame", {}, {
					Fragment = createFragment({
						SubFragment = createFragment({
							Child = createElement(childClassName),
						}),
					}),
				})
			end

			local element = createElement(ComponentWithFragment)

			local result = shallow(element)

			local children = result:find({
				className = childClassName
			})

			expect(#children).to.equal(1)
		end)
	end)
end