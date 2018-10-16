local Type = require(script.Parent.Type)
local ElementKind = require(script.Parent.ElementKind)
local ChildUtils = require(script.Parent.ChildUtils)

--[[
	The reconciler is the mechanism in Roact that constructs the virtual tree
	that later gets turned into concrete objects by the renderer.

	Roact's reconciler is constructed with the renderer as an argument, which
	enables switching to different renderers for different platforms or
	scenarios.

	When testing the reconciler itself, it's common to use `NoopRenderer` with
	spies replacing some methods. The default (and only) reconciler interface
	exposed by Roact right now uses `RobloxRenderer`.

	The reconciler primarily deals with a few kinds of objects:
	- Tree
	- Virtual Node
	- Component Instance
	- Element

	Trees are... (TODO)

	Virtual Nodes are... (TODO)

	Component Instances are... (TODO)

	Elements are... (TODO)
]]
local function createReconciler(renderer)
	local reconciler
	local mountVirtualNode
	local updateVirtualNode

	--[[
		Utility to update the children of a virtual node based on zero or more
		updated children given as elements.
	]]
	local function updateVirtualNodeChildren(virtualNode, newChildElements)
		assert(Type.of(virtualNode) == Type.VirtualNode)

		local removeKeys = {}

		-- Changed or removed children
		for childKey, childNode in pairs(virtualNode.children) do
			local newElement = ChildUtils.getChildByKey(newChildElements, childKey)
			local newNode = updateVirtualNode(childNode, newElement)

			if newNode ~= nil then
				virtualNode.children[childKey] = newNode
			else
				removeKeys[childKey] = true
			end
		end

		for childKey in pairs(removeKeys) do
			virtualNode.children[childKey] = nil
		end

		-- Added children
		for childKey, newElement in ChildUtils.iterateChildren(newChildElements) do
			local childNode = virtualNode.children[childKey]

			local concreteKey = childKey
			if childKey == ChildUtils.UseParentKey then
				concreteKey = virtualNode.key
			end

			if childNode == nil then
				virtualNode.children[childKey] = mountVirtualNode(newElement, virtualNode.hostObject, concreteKey)
			end
		end
	end

	--[[
		Unmounts the given virtual node and releases any held resources.
	]]
	local function unmountVirtualNode(virtualNode)
		assert(Type.of(virtualNode) == Type.VirtualNode)

		local kind = ElementKind.of(virtualNode.currentElement)

		if kind == ElementKind.Host then
			renderer.unmountHostNode(reconciler, virtualNode)
		elseif kind == ElementKind.Function then
			for _, child in pairs(virtualNode.children) do
				unmountVirtualNode(child)
			end
		elseif kind == ElementKind.Stateful then
			virtualNode.instance:__unmount()
		elseif kind == ElementKind.Portal then
			error("NYI")
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end
	end

	local function updateFunctionVirtualNode(virtualNode, newElement)
		local renderResult = newElement.component(newElement.props)

		updateVirtualNodeChildren(virtualNode, renderResult)
	end

	--[[
		Update the given virtual node using a new element describing what it
		should transform into.

		`updateVirtualNode` will return a new virtual node that should replace the
		passed in virtual node. This is because a virtual node can be updated
		with an element referencing a different component!

		In that case, `updateVirtualNode` will unmount the input virtual node,
		mount a new virtual node, and return it in this case, while also issuing
		a warning to the user.
	]]
	function updateVirtualNode(virtualNode, newElement)
		assert(Type.of(virtualNode) == Type.VirtualNode)
		assert(Type.of(newElement) == Type.Element or typeof(newElement) == "boolean" or newElement == nil)

		if typeof(newElement) == "boolean" or newElement == nil then
			unmountVirtualNode(virtualNode)
			return nil
		end

		if virtualNode.currentElement.component ~= newElement.component then
			-- TODO: Better message
			warn("Component changed type!")

			local hostParent = virtualNode.hostParent
			local key = virtualNode.key

			unmountVirtualNode(virtualNode)
			return mountVirtualNode(newElement, hostParent, key)
		end

		local kind = ElementKind.of(newElement)

		if kind == ElementKind.Host then
			return renderer.updateHostNode(reconciler, virtualNode, newElement)
		elseif kind == ElementKind.Function then
			updateFunctionVirtualNode(virtualNode, newElement)

			return virtualNode
		elseif kind == ElementKind.Stateful then
			virtualNode.instance:__update(newElement, nil)

			return virtualNode
		elseif kind == ElementKind.Portal then
			error("NYI")
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end
	end

	--[[
		Constructs a new virtual node but not does mount it.
	]]
	local function createVirtualNode(element, hostParent, key)
		assert(Type.of(element) == Type.Element or typeof(element) == "boolean")
		assert(typeof(hostParent) == "Instance" or hostParent == nil)
		assert(typeof(key) == "string")

		return {
			[Type] = Type.VirtualNode,
			currentElement = element,

			-- TODO: Allow children to be a single node?
			children = {},

			-- Less certain about these properties:
			hostParent = hostParent,
			key = key,
		}
	end

	local function mountFunctionVirtualNode(virtualNode)
		local element = virtualNode.currentElement
		local hostParent = virtualNode.hostParent
		local key = virtualNode.key

		local renderResult = element.component(element.props)

		for childKey, childElement in ChildUtils.iterateChildren(renderResult) do
			local concreteKey = childKey
			if childKey == ChildUtils.UseParentKey then
				concreteKey = key
			end

			local childNode = reconciler.mountVirtualNode(childElement, hostParent, concreteKey)

			virtualNode.children[childKey] = childNode
		end
	end

	--[[
		Constructs a new virtual node and mounts it, but does not place it into
		the tree.
	]]
	function mountVirtualNode(element, hostParent, key)
		assert(Type.of(element) == Type.Element or typeof(element) == "boolean")
		assert(typeof(hostParent) == "Instance" or hostParent == nil)
		assert(typeof(key) == "string")

		-- Boolean values render as nil to enable terse conditional rendering.
		if typeof(element) == "boolean" then
			return nil
		end

		local kind = ElementKind.of(element)

		local virtualNode = createVirtualNode(element, hostParent, key)

		if kind == ElementKind.Host then
			renderer.mountHostNode(reconciler, virtualNode)

			return virtualNode
		elseif kind == ElementKind.Function then
			mountFunctionVirtualNode(virtualNode)

			return virtualNode
		elseif kind == ElementKind.Stateful then
			element.component:__mount(reconciler, virtualNode)

			return virtualNode
		elseif kind == ElementKind.Portal then
			error("NYI")
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end
	end

	--[[
		Constructs a new Roact tree, constructs a root virtual node for it, and
		mounts it.
	]]
	local function mountTree(element, hostParent, key)
		assert(Type.of(element) == Type.Element)
		assert(typeof(hostParent) == "Instance" or hostParent == nil)
		assert(typeof(key) == "string" or key == nil)

		if key == nil then
			key = "Foo"
		end

		local tree = {
			[Type] = Type.Tree,

			-- TODO: Move these fields into an internal data table?

			-- The root node of the tree, which starts into the hierarchy of
			-- Roact component instances.
			rootNode = nil,

			mounted = true,
		}

		tree.rootNode = mountVirtualNode(element, hostParent, key)

		return tree
	end

	--[[
		Unmounts the tree, freeing all of its resources.

		No further operations should be done on the tree after it's been
		unmounted, as indictaed by its the `mounted` field.
	]]
	local function unmountTree(tree)
		assert(Type.of(tree) == Type.Tree)
		assert(tree.mounted, "Cannot unmounted a Roact tree that has already been unmounted")

		tree.mounted = false

		if tree.rootNode ~= nil then
			unmountVirtualNode(tree.rootNode)
		end
	end

	--[[
		Utility method for updating the root node of a tree given a new element.
	]]
	local function updateTree(tree, newElement)
		assert(Type.of(tree) == Type.Tree)
		assert(Type.of(newElement) == Type.Element)

		tree.rootNode = updateVirtualNode(tree.rootNode, newElement)

		return tree
	end

	reconciler = {
		mountTree = mountTree,
		unmountTree = unmountTree,
		updateTree = updateTree,

		createVirtualNode = createVirtualNode,
		mountVirtualNode = mountVirtualNode,
		unmountVirtualNode = unmountVirtualNode,
		updateVirtualNode = updateVirtualNode,
		updateVirtualNodeChildren = updateVirtualNodeChildren,
	}

	return reconciler
end

return createReconciler