-- Tests loosely adapted from those found at:
-- * https://github.com/facebook/react/blob/v17.0.1/packages/react/src/__tests__/forwardRef-test.js
-- * https://github.com/facebook/react/blob/v17.0.1/packages/react/src/__tests__/forwardRef-test.internal.js
return function()
	local assign = require(script.Parent.assign)
	local createElement = require(script.Parent.createElement)
	local createRef = require(script.Parent.createRef)
	local forwardRef = require(script.Parent.forwardRef)
	local createReconciler = require(script.Parent.createReconciler)
	local Component = require(script.Parent.Component)
	local GlobalConfig = require(script.Parent.GlobalConfig)
	local Ref = require(script.Parent.PropMarkers.Ref)

	local RobloxRenderer = require(script.Parent.RobloxRenderer)

	local reconciler = createReconciler(RobloxRenderer)

	it("should update refs when switching between children", function()
		local function FunctionComponent(props)
			local forwardedRef = props.forwardedRef
			local setRefOnDiv = props.setRefOnDiv
			-- deviation: clearer to express this way, since we don't have real
			-- ternaries
			local firstRef, secondRef
			if setRefOnDiv then
				firstRef = forwardedRef
			else
				secondRef = forwardedRef
			end
			return createElement("Frame", nil, {
				First = createElement("Frame", {
					[Ref] = firstRef,
				}, {
					Child = createElement("TextLabel", {
						Text = "First",
					}),
				}),
				Second = createElement("ScrollingFrame", {
					[Ref] = secondRef,
				}, {
					Child = createElement("TextLabel", {
						Text = "Second",
					}),
				}),
			})
		end

		local RefForwardingComponent = forwardRef(function(props, ref)
			return createElement(FunctionComponent, assign({}, props, { forwardedRef = ref }))
		end)

		local ref = createRef()

		local element = createElement(RefForwardingComponent, {
			[Ref] = ref,
			setRefOnDiv = true,
		})
		local tree = reconciler.mountVirtualTree(element, nil, "switch refs")
		expect(ref.current.ClassName).to.equal("Frame")
		reconciler.unmountVirtualTree(tree)

		element = createElement(RefForwardingComponent, {
			[Ref] = ref,
			setRefOnDiv = false,
		})
		tree = reconciler.mountVirtualTree(element, nil, "switch refs")
		expect(ref.current.ClassName).to.equal("ScrollingFrame")
		reconciler.unmountVirtualTree(tree)
	end)

	it("should support rendering nil", function()
		local RefForwardingComponent = forwardRef(function(_props, _ref)
			return nil
		end)

		local ref = createRef()

		local element = createElement(RefForwardingComponent, { [Ref] = ref })
		local tree = reconciler.mountVirtualTree(element, nil, "nil ref")
		expect(ref.current).to.equal(nil)
		reconciler.unmountVirtualTree(tree)
	end)

	it("should support rendering nil for multiple children", function()
		local RefForwardingComponent = forwardRef(function(_props, _ref)
			return nil
		end)

		local ref = createRef()

		local element = createElement("Frame", nil, {
			NoRef1 = createElement("Frame"),
			WithRef = createElement(RefForwardingComponent, { [Ref] = ref }),
			NoRef2 = createElement("Frame"),
		})
		local tree = reconciler.mountVirtualTree(element, nil, "multiple children nil ref")
		expect(ref.current).to.equal(nil)
		reconciler.unmountVirtualTree(tree)
	end)

	-- We could support this by having forwardRef return a stateful component,
	-- but it's likely not necessary
	itSKIP("should support defaultProps", function()
		local function FunctionComponent(props)
			local forwardedRef = props.forwardedRef
			local optional = props.optional
			local required = props.required
			return createElement("Frame", {
				[Ref] = forwardedRef,
			}, {
				OptionalChild = optional,
				RequiredChild = required,
			})
		end

		local RefForwardingComponent = forwardRef(function(props, ref)
			return createElement(
				FunctionComponent,
				assign({}, props, {
					forwardedRef = ref,
				})
			)
		end)
		RefForwardingComponent.defaultProps = {
			optional = createElement("TextLabel"),
		}

		local ref = createRef()

		local element = createElement(RefForwardingComponent, {
			[Ref] = ref,
			optional = createElement("Frame"),
			required = createElement("ScrollingFrame"),
		})

		local tree = reconciler.mountVirtualTree(element, nil, "with optional")

		expect(ref.current:FindFirstChild("OptionalChild").ClassName).to.equal("Frame")
		expect(ref.current:FindFirstChild("RequiredChild").ClassName).to.equal("ScrollingFrame")

		reconciler.unmountVirtualTree(tree)
		element = createElement(RefForwardingComponent, {
			[Ref] = ref,
			required = createElement("ScrollingFrame"),
		})
		tree = reconciler.mountVirtualTree(element, nil, "with default")

		expect(ref.current:FindFirstChild("OptionalChild").ClassName).to.equal("TextLabel")
		expect(ref.current:FindFirstChild("RequiredChild").ClassName).to.equal("ScrollingFrame")
		reconciler.unmountVirtualTree(tree)
	end)

	it("should error if not provided a callback when type checking is enabled", function()
		GlobalConfig.scoped({
			typeChecks = true,
		}, function()
			expect(function()
				forwardRef(nil)
			end).to.throw()
		end)

		GlobalConfig.scoped({
			typeChecks = true,
		}, function()
			expect(function()
				forwardRef("foo")
			end).to.throw()
		end)
	end)

	it("should work without a ref to be forwarded", function()
		local function Child()
			return nil
		end

		local function Wrapper(props)
			return createElement(Child, assign({}, props, { [Ref] = props.forwardedRef }))
		end

		local RefForwardingComponent = forwardRef(function(props, ref)
			return createElement(Wrapper, assign({}, props, { forwardedRef = ref }))
		end)

		local element = createElement(RefForwardingComponent, { value = 123 })
		local tree = reconciler.mountVirtualTree(element, nil, "nil ref")
		reconciler.unmountVirtualTree(tree)
	end)

	it("should forward a ref for a single child", function()
		local value
		local function Child(props)
			value = props.value
			return createElement("Frame", {
				[Ref] = props[Ref],
			})
		end

		local function Wrapper(props)
			return createElement(Child, assign({}, props, { [Ref] = props.forwardedRef }))
		end

		local RefForwardingComponent = forwardRef(function(props, ref)
			return createElement(Wrapper, assign({}, props, { forwardedRef = ref }))
		end)

		local ref = createRef()

		local element = createElement(RefForwardingComponent, { [Ref] = ref, value = 123 })
		local tree = reconciler.mountVirtualTree(element, nil, "single child ref")
		expect(value).to.equal(123)
		expect(ref.current.ClassName).to.equal("Frame")
		reconciler.unmountVirtualTree(tree)
	end)

	it("should forward a ref for multiple children", function()
		local function Child(props)
			return createElement("Frame", {
				[Ref] = props[Ref],
			})
		end

		local function Wrapper(props)
			return createElement(Child, assign({}, props, { [Ref] = props.forwardedRef }))
		end

		local RefForwardingComponent = forwardRef(function(props, ref)
			return createElement(Wrapper, assign({}, props, { forwardedRef = ref }))
		end)

		local ref = createRef()

		local element = createElement("Frame", nil, {
			NoRef1 = createElement("Frame"),
			WithRef = createElement(RefForwardingComponent, { [Ref] = ref }),
			NoRef2 = createElement("Frame"),
		})
		local tree = reconciler.mountVirtualTree(element, nil, "multi child ref")
		expect(ref.current.ClassName).to.equal("Frame")
		reconciler.unmountVirtualTree(tree)
	end)

	it("should maintain child instance and ref through updates", function()
		local value
		local function Child(props)
			value = props.value
			return createElement("Frame", {
				[Ref] = props[Ref],
			})
		end

		local function Wrapper(props)
			return createElement(Child, assign({}, props, { [Ref] = props.forwardedRef }))
		end

		local RefForwardingComponent = forwardRef(function(props, ref)
			return createElement(Wrapper, assign({}, props, { forwardedRef = ref }))
		end)

		local setRefCount = 0
		local refValue

		local setRef = function(r)
			setRefCount = setRefCount + 1
			refValue = r
		end

		local element = createElement(RefForwardingComponent, { [Ref] = setRef, value = 123 })
		local tree = reconciler.mountVirtualTree(element, nil, "maintains instance")

		expect(value).to.equal(123)
		expect(refValue.ClassName).to.equal("Frame")
		expect(setRefCount).to.equal(1)

		element = createElement(RefForwardingComponent, { [Ref] = setRef, value = 456 })
		tree = reconciler.updateVirtualTree(tree, element)

		expect(value).to.equal(456)
		expect(setRefCount).to.equal(1)
		reconciler.unmountVirtualTree(tree)
	end)

	it("should not re-run the render callback on a deep setState", function()
		local inst
		local renders = {}

		local Inner = Component:extend("Inner")
		function Inner:render()
			table.insert(renders, "Inner")
			inst = self
			return createElement("Frame", { [Ref] = self.props.forwardedRef })
		end

		local function Middle(props)
			table.insert(renders, "Middle")
			return createElement(Inner, props)
		end

		local Forward = forwardRef(function(props, ref)
			table.insert(renders, "Forward")
			return createElement(Middle, assign({}, props, { forwardedRef = ref }))
		end)

		local function App()
			table.insert(renders, "App")
			return createElement(Forward)
		end

		local tree = reconciler.mountVirtualTree(createElement(App), nil, "deep setState")
		expect(#renders).to.equal(4)
		expect(renders[1]).to.equal("App")
		expect(renders[2]).to.equal("Forward")
		expect(renders[3]).to.equal("Middle")
		expect(renders[4]).to.equal("Inner")

		renders = {}
		inst:setState({})
		expect(#renders).to.equal(1)
		expect(renders[1]).to.equal("Inner")
		reconciler.unmountVirtualTree(tree)
	end)

	it("should not include the ref in the forwarded props", function()
		local capturedProps
		local function CaptureProps(props)
			capturedProps = props
			return createElement("Frame", { [Ref] = props.forwardedRef })
		end

		local RefForwardingComponent = forwardRef(function(props, ref)
			return createElement(CaptureProps, assign({}, props, { forwardedRef = ref }))
		end)

		local ref = createRef()
		local element = createElement(RefForwardingComponent, {
			[Ref] = ref,
		})

		local tree = reconciler.mountVirtualTree(element, nil, "no ref in props")
		expect(capturedProps).to.be.ok()
		expect(capturedProps.forwardedRef).to.equal(ref)
		expect(capturedProps[Ref]).to.equal(nil)
		reconciler.unmountVirtualTree(tree)
	end)
end
