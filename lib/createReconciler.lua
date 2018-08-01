local Type = require(script.Parent.Type)
local ElementKind = require(script.Parent.ElementKind)
local Core = require(script.Parent.Core)

local function noop()
	return nil
end

local function iterateElements(childOrChildren)
	local richType = Type.of(childOrChildren)

	-- Single child, the simplest case!
	if richType == Type.Element then
		local called = false

		return function()
			if called then
				return nil
			else
				called = true
				return 1, childOrChildren
			end
		end
	end

	-- This is a Roact-speciifc object, and it's the wrong kind.
	if richType ~= nil then
		error("Invalid children")
	end

	local regularType = typeof(childOrChildren)

	-- A dictionary of children, hopefully!
	-- TODO: Is this too flaky? Should we introduce a Fragment type like React?
	if regularType == "table" then
		return pairs(childOrChildren)
	end

	if childOrChildren == nil or regularType == "boolean" then
		return noop
	end

	error("Invalid children")
end

local function createReconciler(renderer)
	local reconciler
	local mountNode
	local reconcileNode

	local function reconcileChildren(node, newChildElements)
		for key, newElement in iterateElements(newChildElements) do
			local node = node.children[key]

			if node ~= nil then
				node.children[key] = reconcileNode(node, newElement)
			else
				-- TODO: Route parent Instance through nodes
				node.children[key] = mountNode(newElement, nil, key)
			end
		end

		for key, childNode in pairs(node.children) do
			-- TODO: Don't invalidate this iterator!
			-- TODO: Handle case of single child and no children
			node.children[key] = reconcileNode(childNode, newChildElements[key])
		end
	end

	local function unmountNode(node)
		assert(Type.of(node) == Type.Node)

		local kind = ElementKind.of(node.currentElement)

		if kind == ElementKind.Host then
			renderer.unmountHostNode(reconciler, node)
		elseif kind == ElementKind.Function then
			for _, child in pairs(node.children) do
				unmountNode(child)
			end
		elseif kind == ElementKind.Stateful then
			-- TODO: Fire willUnmount

			for _, child in pairs(node.children) do
				unmountNode(child)
			end
		elseif kind == ElementKind.Portal then
			error("NYI")
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end
	end

	function reconcileNode(node, newElement)
		assert(Type.of(node) == Type.Node)
		assert(Type.of(newElement) == Type.Element or typeof(newElement) == "boolean" or newElement == nil)

		if typeof(newElement) == "boolean" or newElement == nil then
			return unmountNode(node)
		end

		if node.currentElement.component ~= newElement.component then
			error("don't do that")
		end

		local kind = ElementKind.of(newElement)

		if kind == ElementKind.Host then
			return renderer.reconcileHostNode(reconciler, node, newElement)
		elseif kind == ElementKind.Function then
			error("NYI")
		elseif kind == ElementKind.Stateful then
			-- TODO: Fire willUpdate

			error("NYI")

			-- TODO: Fire didUpdate
		elseif kind == ElementKind.Portal then
			error("NYI")
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end
	end

	function mountNode(element, hostParent, key)
		assert(Type.of(element) == Type.Element or typeof(element) == "boolean")
		assert(typeof(hostParent) == "Instance" or hostParent == nil)
		assert(typeof(key) == "string")

		-- Boolean values reconcile as nil to enable terse conditional rendering.
		if typeof(element) == "boolean" then
			return nil
		end

		local kind = ElementKind.of(element)

		local node = {
			[Type] = Type.Node,
			currentElement = element,
			children = {},
		}

		if kind == ElementKind.Host then
			renderer.mountHostNode(reconciler, node, element, hostParent, key)

			return node
		elseif kind == ElementKind.Function then
			local renderResult = element.component(element.props)

			for childKey, childElement in iterateElements(renderResult) do
				local childNode = mountNode(childElement, hostParent, childKey)

				-- TODO: Figure out how to preserve 'key' if a single value is
				-- returned.
				node.children[childKey] = childNode
			end

			return node
		elseif kind == ElementKind.Stateful then
			local instance = element.component:__new(element.props)
			node.instance = instance

			local renderResult = instance:render()

			-- TODO: Move logic into Component?
			-- Maybe component should become logicless?
			for childKey, childElement in iterateElements(renderResult) do
				local childNode = mountNode(childElement, hostParent, childKey)

				-- TODO: Figure out how to preserve 'key' if a single value is
				-- returned.
				node.children[childKey] = childNode
			end

			-- TODO: Fire didMount

			return node
		elseif kind == ElementKind.Portal then
			error("NYI")
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end
	end

	local function mountTree(element, hostParent, key)
		assert(Type.of(element) == Type.Element)
		assert(typeof(hostParent) == "Instance" or hostParent == nil)
		assert(typeof(key) == "string" or key == nil)

		if key == nil then
			key = "Foo"
		end

		local tree = {
			[Type] = Type.Tree,

			-- The root node of the tree, which starts into the hierarchy of
			-- Roact component instances.
			rootNode = nil,

			mounted = true,
		}

		tree.rootNode = mountNode(element, hostParent, key)

		return tree
	end

	local function unmountTree(tree)
		assert(Type.of(tree) == Type.Tree)
		assert(tree.mounted, "Cannot unmounted a Roact tree that has already been unmounted")

		tree.mounted = false

		unmountNode(tree.rootNode)
	end

	local function reconcileTree(tree, newElement)
		assert(Type.of(tree) == Type.Tree)
		assert(Type.of(newElement) == Type.Element)

		tree.rootNode = reconcileNode(tree.rootNode, newElement)

		return tree
	end

	reconciler = {
		mountTree = mountTree,
		unmountTree = unmountTree,
		reconcileTree = reconcileTree,
		mountNode = mountNode,
		unmountNode = unmountNode,
		reconcileNode = reconcileNode,
	}

	return reconciler
end

return createReconciler