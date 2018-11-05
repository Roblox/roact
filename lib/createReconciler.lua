local Type = require(script.Parent.Type)
local ElementKind = require(script.Parent.ElementKind)
local ChildUtils = require(script.Parent.ChildUtils)
local Children = require(script.Parent.PropMarkers.Children)
local Logging = require(script.Parent.Logging)

--[[
	The reconciler is the mechanism in Roact that constructs the virtual tree
	that later gets turned into concrete objects by the renderer.

	Roact's reconciler is constructed with the renderer as an argument, which
	enables switching to different renderers for different platforms or
	scenarios.

	When testing the reconciler itself, it's common to use `NoopRenderer` with
	spies replacing some methods. The default (and only) reconciler interface
	exposed by Roact right now uses `RobloxRenderer`.
]]
local function createReconciler(renderer)
	local reconciler
	local mountVirtualNode
	local updateVirtualNode
	local unmountVirtualNode

	--[[
		Unmount the given virtualNode, replacing it with a new node described by
		the given element.

		Preserves host properties and depth.
	]]
	local function replaceVirtualNode(virtualNode, newElement)
		local hostParent = virtualNode.hostParent
		local hostKey = virtualNode.hostKey
		local depth = virtualNode.depth

		unmountVirtualNode(virtualNode)
		local newNode = mountVirtualNode(newElement, hostParent, hostKey)
		newNode.depth = depth

		return newNode
	end

	--[[
		Utility to update the children of a virtual node based on zero or more
		updated children given as elements.
	]]
	local function updateVirtualNodeChildren(virtualNode, hostParent, newChildElements)
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
			local concreteKey = childKey
			if childKey == ChildUtils.UseParentKey then
				concreteKey = virtualNode.hostKey
			end

			if virtualNode.children[childKey] == nil then
				local childNode = mountVirtualNode(newElement, hostParent, concreteKey)
				childNode.depth = virtualNode.depth + 1
				virtualNode.children[childKey] = childNode
			end
		end
	end

	--[[
		Unmounts the given virtual node and releases any held resources.
	]]
	function unmountVirtualNode(virtualNode)
		assert(Type.of(virtualNode) == Type.VirtualNode)

		local kind = ElementKind.of(virtualNode.currentElement)

		if kind == ElementKind.Host then
			renderer.unmountHostNode(reconciler, virtualNode)
		elseif kind == ElementKind.Function then
			for _, childNode in pairs(virtualNode.children) do
				unmountVirtualNode(childNode)
			end
		elseif kind == ElementKind.Stateful then
			virtualNode.instance:__unmount()
		elseif kind == ElementKind.Portal then
			for _, childNode in pairs(virtualNode.children) do
				unmountVirtualNode(childNode)
			end
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end
	end

	local function updateFunctionVirtualNode(virtualNode, newElement)
		local children = newElement.component(newElement.props)

		updateVirtualNodeChildren(virtualNode, virtualNode.hostParent, children)
	end

	local function updatePortalVirtualNode(virtualNode, newElement)
		local oldElement = virtualNode.currentElement
		local oldTargetHostParent = oldElement.props.target

		local targetHostParent = newElement.props.target

		-- TODO: Error message
		assert(renderer.isHostObject(targetHostParent))

		if targetHostParent ~= oldTargetHostParent then
			-- TODO: Better warning
			Logging.warn("Portal changed target!")

			return replaceVirtualNode(virtualNode, newElement)
		end

		local children = newElement.props[Children]

		updateVirtualNodeChildren(virtualNode, targetHostParent, children)

		return virtualNode
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
	function updateVirtualNode(virtualNode, newElement, newState)
		assert(Type.of(virtualNode) == Type.VirtualNode)
		assert(Type.of(newElement) == Type.Element or typeof(newElement) == "boolean" or newElement == nil)

		if typeof(newElement) == "boolean" or newElement == nil then
			unmountVirtualNode(virtualNode)
			return nil
		end

		if virtualNode.currentElement.component ~= newElement.component then
			-- TODO: Better message
			Logging.warn("Component changed type!")

			return replaceVirtualNode(virtualNode, newElement)
		end

		local kind = ElementKind.of(newElement)

		local resultNode = virtualNode

		if kind == ElementKind.Host then
			resultNode = renderer.updateHostNode(reconciler, virtualNode, newElement)
		elseif kind == ElementKind.Function then
			updateFunctionVirtualNode(virtualNode, newElement)
		elseif kind == ElementKind.Stateful then
			virtualNode.instance:__update(newElement, newState)
		elseif kind == ElementKind.Portal then
			resultNode = updatePortalVirtualNode(virtualNode, newElement)
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end

		virtualNode.currentElement = newElement

		return resultNode
	end

	--[[
		Constructs a new virtual node but not does mount it.
	]]
	local function createVirtualNode(element, hostParent, hostKey)
		assert(Type.of(element) == Type.Element or typeof(element) == "boolean")
		assert(renderer.isHostObject(hostParent) or hostParent == nil)
		assert(typeof(hostKey) == "string")

		return {
			[Type] = Type.VirtualNode,
			currentElement = element,
			depth = 1,

			-- TODO: Allow children to be a single node?
			children = {},

			-- Less certain about these properties:
			hostParent = hostParent,
			hostKey = hostKey,
		}
	end

	local function mountFunctionVirtualNode(virtualNode)
		local element = virtualNode.currentElement

		local children = element.component(element.props)

		updateVirtualNodeChildren(virtualNode, virtualNode.hostParent, children)
	end

	local function mountPortalVirtualNode(virtualNode)
		local element = virtualNode.currentElement

		local targetHostParent = element.props.target
		local children = element.props[Children]

		assert(renderer.isHostObject(targetHostParent))

		updateVirtualNodeChildren(virtualNode, targetHostParent, children)
	end

	--[[
		Constructs a new virtual node and mounts it, but does not place it into
		the tree.
	]]
	function mountVirtualNode(element, hostParent, hostKey)
		assert(Type.of(element) == Type.Element or typeof(element) == "boolean")
		assert(typeof(hostParent) == "Instance" or hostParent == nil)
		assert(typeof(hostKey) == "string")

		-- Boolean values render as nil to enable terse conditional rendering.
		if typeof(element) == "boolean" then
			return nil
		end

		local kind = ElementKind.of(element)

		local virtualNode = createVirtualNode(element, hostParent, hostKey)

		if kind == ElementKind.Host then
			renderer.mountHostNode(reconciler, virtualNode)
		elseif kind == ElementKind.Function then
			mountFunctionVirtualNode(virtualNode)
		elseif kind == ElementKind.Stateful then
			element.component:__mount(reconciler, virtualNode)
		elseif kind == ElementKind.Portal then
			mountPortalVirtualNode(virtualNode)
		else
			error(("Unknown ElementKind %q"):format(tostring(kind), 2))
		end

		return virtualNode
	end

	--[[
		Constructs a new Roact virtual tree, constructs a root node for
		it, and mounts it.
	]]
	local function mountVirtualTree(element, hostParent, hostKey)
		assert(Type.of(element) == Type.Element)
		assert(typeof(hostParent) == "Instance" or hostParent == nil)
		assert(typeof(hostKey) == "string" or hostKey == nil)

		if hostKey == nil then
			hostKey = "Foo"
		end

		local tree = {
			[Type] = Type.VirtualTree,

			-- TODO: Move these fields into an internal data table?

			-- The root node of the tree, which starts into the hierarchy of
			-- Roact component instances.
			rootNode = nil,

			mounted = true,
		}

		tree.rootNode = mountVirtualNode(element, hostParent, hostKey)

		return tree
	end

	--[[
		Unmounts the virtual tree, freeing all of its resources.

		No further operations should be done on the tree after it's been
		unmounted, as indictaed by its the `mounted` field.
	]]
	local function unmountVirtualTree(tree)
		assert(Type.of(tree) == Type.VirtualTree)
		assert(tree.mounted, "Cannot unmounted a Roact tree that has already been unmounted")

		tree.mounted = false

		if tree.rootNode ~= nil then
			unmountVirtualNode(tree.rootNode)
		end
	end

	--[[
		Utility method for updating the root node of a virtual tree given a new
		element.
	]]
	local function updateVirtualTree(tree, newElement)
		assert(Type.of(tree) == Type.VirtualTree)
		assert(Type.of(newElement) == Type.Element)

		tree.rootNode = updateVirtualNode(tree.rootNode, newElement)

		return tree
	end

	reconciler = {
		mountVirtualTree = mountVirtualTree,
		unmountVirtualTree = unmountVirtualTree,
		updateVirtualTree = updateVirtualTree,

		createVirtualNode = createVirtualNode,
		mountVirtualNode = mountVirtualNode,
		unmountVirtualNode = unmountVirtualNode,
		updateVirtualNode = updateVirtualNode,
		updateVirtualNodeChildren = updateVirtualNodeChildren,
	}

	return reconciler
end

return createReconciler