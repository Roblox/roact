local Type = require(script.Parent.Type)
local ElementKind = require(script.Parent.ElementKind)
local ChildUtils = require(script.Parent.ChildUtils)

local function createReconciler(renderer)
	local reconciler
	local mountNode
	local updateNode

	local function updateNodeChildren(node, newChildElements)
		assert(Type.of(node) == Type.Node)

		local removeKeys = {}

		-- Changed or removed children
		for childKey, childNode in pairs(node.children) do
			local newElement = ChildUtils.getChildByKey(newChildElements, childKey)
			local newNode = updateNode(childNode, newElement)

			if newNode ~= nil then
				node.children[childKey] = newNode
			else
				removeKeys[childKey] = true
			end
		end

		for childKey in pairs(removeKeys) do
			node.children[childKey] = nil
		end

		-- Added children
		for childKey, newElement in ChildUtils.iterateChildren(newChildElements) do
			local childNode = node.children[childKey]

			local concreteKey = childKey
			if childKey == ChildUtils.UseParentKey then
				concreteKey = node.key
			end

			if childNode == nil then
				node.children[childKey] = mountNode(newElement, node.hostObject, concreteKey)
			end
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
			node.instance:__unmount()
		elseif kind == ElementKind.Portal then
			error("NYI")
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end
	end

	local function updateFunctionNode(node, newElement)
		local renderResult = newElement.component(newElement.props)

		updateNodeChildren(node, renderResult)
	end

	function updateNode(node, newElement)
		assert(Type.of(node) == Type.Node)
		assert(Type.of(newElement) == Type.Element or typeof(newElement) == "boolean" or newElement == nil)

		if typeof(newElement) == "boolean" or newElement == nil then
			unmountNode(node)
			return nil
		end

		if node.currentElement.component ~= newElement.component then
			-- TODO: Better message
			warn("Component changed type!")

			local hostParent = node.hostParent
			local key = node.key

			unmountNode(node)
			return mountNode(newElement, hostParent, key)
		end

		local kind = ElementKind.of(newElement)

		if kind == ElementKind.Host then
			return renderer.updateHostNode(reconciler, node, newElement)
		elseif kind == ElementKind.Function then
			updateFunctionNode(node, newElement)

			return node
		elseif kind == ElementKind.Stateful then
			node.instance:__update(newElement, nil)

			return node
		elseif kind == ElementKind.Portal then
			error("NYI")
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end
	end

	local function createNode(element, hostParent, key)
		assert(Type.of(element) == Type.Element or typeof(element) == "boolean")
		assert(typeof(hostParent) == "Instance" or hostParent == nil)
		assert(typeof(key) == "string")

		return {
			[Type] = Type.Node,
			currentElement = element,

			-- TODO: Allow children to be a single node?
			children = {},

			-- Less certain about these properties:
			hostParent = hostParent,
			key = key,
		}
	end

	local function mountFunctionNode(node)
		local element = node.currentElement
		local hostParent = node.hostParent
		local key = node.key

		local renderResult = element.component(element.props)

		for childKey, childElement in ChildUtils.iterateChildren(renderResult) do
			local concreteKey = childKey
			if childKey == ChildUtils.UseParentKey then
				concreteKey = key
			end

			local childNode = reconciler.mountNode(childElement, hostParent, concreteKey)

			node.children[childKey] = childNode
		end
	end

	function mountNode(element, hostParent, key)
		assert(Type.of(element) == Type.Element or typeof(element) == "boolean")
		assert(typeof(hostParent) == "Instance" or hostParent == nil)
		assert(typeof(key) == "string")

		-- Boolean values render as nil to enable terse conditional rendering.
		if typeof(element) == "boolean" then
			return nil
		end

		local kind = ElementKind.of(element)

		local node = createNode(element, hostParent, key)

		if kind == ElementKind.Host then
			renderer.mountHostNode(reconciler, node)

			return node
		elseif kind == ElementKind.Function then
			mountFunctionNode(node)

			return node
		elseif kind == ElementKind.Stateful then
			element.component:__mount(reconciler, node)

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

		if tree.rootNode ~= nil then
			unmountNode(tree.rootNode)
		end
	end

	local function updateTree(tree, newElement)
		assert(Type.of(tree) == Type.Tree)
		assert(Type.of(newElement) == Type.Element)

		tree.rootNode = updateNode(tree.rootNode, newElement)

		return tree
	end

	reconciler = {
		mountTree = mountTree,
		unmountTree = unmountTree,
		updateTree = updateTree,

		createNode = createNode,
		mountNode = mountNode,
		unmountNode = unmountNode,
		updateNode = updateNode,
		updateNodeChildren = updateNodeChildren,
	}

	return reconciler
end

return createReconciler