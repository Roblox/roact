local Core = require(script.Parent.Core)
local Type = require(script.Parent.Type)
local Symbol = require(script.Parent.Symbol)
local TaskScheduler = require(script.Parent.TaskScheduler)

local DEFAULT_TREE_CONFIG = {
	useAsyncScheduler = true,
	asyncSchedulerBudgetPerFrameMs = 12 / 1000
}

-- Used to mark a child that is going to be mounted, but is not yet.
local MountingNode = Symbol.named("MountingNode")

local function makeConfigObject(source)
	local config = {}

	for key, value in pairs(source) do
		config[key] = value
	end

	setmetatable(config, {
		__index = function(_, key)
			error(("Invalid config key %q"):format(key))
		end,
		__newindex = function()
			error("Cannot mutate config!")
		end,
	})

	return config
end

local function makeTaskKind(name, options)
	local validate = options.validate
	local perform = options.perform

	assert(typeof(name) == "string")
	assert(typeof(validate) == "function")
	assert(typeof(perform) == "function")

	return function(details)
		-- We want to minimize the chance that these fields will collide with
		-- values put into the task details, since they share a namespace.
		details.taskName = name
		details.taskPerform = perform

		-- Validation is separated so that it can be gated in the future.
		-- It should only ever fail when working on Roact itself.
		validate(details)

		return details
	end
end

local taskMountNode
taskMountNode = makeTaskKind("MountNode", {
	validate = function(task)
		assert(Type.is(task.element, Type.Element))
		assert(typeof(task.key) == "string")
		assert(Type.is(task.parentNode, Type.Node) or typeof(task.parentNode) == "nil")
		assert(typeof(task.parentRbx) == "Instance" or typeof(task.parentRbx) == "nil")
		assert(typeof(task.isTreeRoot) == "boolean")
		assert(typeof(task.nodeDepth) == "number")
	end,

	perform = function(task, tree)
		local element = task.element
		local key = task.key
		local parentNode = task.parentNode
		local parentRbx = task.parentRbx
		local isTreeRoot = task.isTreeRoot
		local nodeDepth = task.nodeDepth

		local node = {
			[Type] = Type.Node,
			children = {},
			element = element,
		}

		if typeof(element.component) == "string" then
			local rbx = Instance.new(element.component)
			rbx.Name = key

			node.rbx = rbx

			for prop, value in pairs(element.props) do
				if prop == Core.Children then
					for childKey, childElement in pairs(value) do
						node.children[childKey] = MountingNode

						tree.scheduler:schedule(taskMountNode({
							element = childElement,
							key = childKey,
							parentNode = node,
							parentRbx = rbx,
							isTreeRoot = false,
							nodeDepth = nodeDepth + 1,
						}))
					end
				else
					rbx[prop] = value
				end
			end

			tree.scheduler:schedule(function()
				rbx.Parent = parentRbx

				if isTreeRoot then
					tree.rootNode = node
				else
					assert(parentNode.children[key] == MountingNode, "Expected parent node to be prepared for me to mount!")

					parentNode.children[key] = node
				end
			end)
		else
			error("NYI: mounting non-string components")
		end
	end,
})

local taskUnmountNode
taskUnmountNode = makeTaskKind("UnmountNode", {
	validate = function(task)
		assert(Type.is(task.node, Type.Node))
	end,

	perform = function(task, tree)
		local node = task.node

		local nodesToVisit = {node}
		local visitIndex = 1
		local nodesToDestroy = {}

		while true do
			local visitingNode = nodesToVisit[visitIndex]

			if visitingNode == nil then
				break
			end

			for _, childNode in pairs(node.children) do
				table.insert(nodesToVisit, childNode)
			end

			table.insert(nodesToDestroy, visitingNode)

			visitIndex = visitIndex + 1
		end

		-- Destroy from back-to-front in order to destroy the nodes deepest in
		-- the tree first.
		for i = #nodesToDestroy, 1, -1 do
			local destroyNode = nodesToDestroy[i]

			-- TODO: More complicated destruction logic with regards to non-
			-- primitive components

			destroyNode.rbx:Destroy()
		end
	end,
})

local taskReconcileNode
taskReconcileNode = makeTaskKind("ReconcileNode", {
	validate = function(task)
		assert(Type.is(task.node, Type.Node))
		assert(Type.is(task.toElement, Type.Element))
	end,

	perform = function(task, tree)
		local node = task.node
		local toElement = task.toElement

		local fromElement = node.element

		-- TODO: Branch on kind of node
		-- TODO: Check if component type changed

		local visitedProps = {}

		for prop, newValue in pairs(toElement.props) do
			visitedProps[prop] = true
			local oldValue = fromElement.props[prop]

			print("Checking prop", prop, oldValue, newValue)

			if newValue == oldValue then
				print("\tProp is the same.")
			else
				if prop == Core.Children then
					print("\tReconciling children...")

					for key, newChildElement in pairs(newValue) do
						local childNode = node.children[key]

						local oldChildElement = oldValue[key]

						-- TODO: What if oldValue[Core.Children] is nil?

						if oldChildElement == nil then
							warn("NYI: creating children in reconciler")
						elseif newChildElement ~= oldChildElement then
							print("\t\tScheduling reconcile of child", key)

							tree.scheduler:schedule(taskReconcileNode({
								node = childNode,
								toElement = newChildElement,
							}))
						end
					end

					for key in pairs(oldValue) do
						local newChildElement = newValue[key]
						local childNode = node.children[key]

						if newChildElement == nil then
							print("\t\tScheduling unmount of child", key)
							tree.scheduler:schedule(taskUnmountNode({
								node = childNode,
							}))
						end
					end
				else
					print("\tSetting", prop, newValue)
					node.rbx[prop] = newValue
				end
			end
		end

		for prop in pairs(fromElement.props) do
			if not visitedProps[prop] then
				-- TODO: Use real mechanism for setting default values
				node.rbx[prop] = nil
			end
		end
	end,
})

local function mountTree(element, parentRbx, key)
	assert(Type.is(element, Type.Element))
	assert(typeof(parentRbx) == "Instance" or parentRbx == nil)
	assert(typeof(key) == "string")

	-- TODO: Accept config parameter and typecheck values
	local config = makeConfigObject(DEFAULT_TREE_CONFIG)

	local tree = {
		[Type] = Type.Tree,

		-- A list of all signal connections, intended to be cleaned up all at
		-- once when the tree is unmounted.
		connections = {},

		-- Tracks whether the tree is currently mounted. Scheduling new tasks
		-- against a tree that has been unmounted should be an error.
		mounted = true,

		-- The root node of the tree, which starts into the hierarchy of Roact
		-- component instances.
		rootNode = nil,

		-- A static configuration, denoting values like which scheduler and
		-- renderer to use.
		config = config,
	}

	local scheduler = TaskScheduler.new(tree, config.useAsyncScheduler, config.asyncSchedulerBudgetPerFrameMs)

	tree.scheduler = scheduler

	scheduler:schedule(taskMountNode({
		element = element,
		key = key,
		parentNode = nil,
		parentRbx = parentRbx,
		isTreeRoot = true,
		nodeDepth = 1,
	}))

	return tree
end

local function unmountTree(tree)
	assert(Type.is(tree, Type.Tree))
	assert(tree.mounted, "not mounted")

	tree.mounted = false

	-- TODO: Flush/cancel existing tasks and unmount asynchronously?

	tree.scheduler:schedule(taskUnmountNode({
		node = tree.rootNode,
	}))

	-- For now, flush the entire tree and unmount synchronously
	tree.scheduler:processSync()
	tree.scheduler:destroy()
end

local function reconcileTree(tree, toElement)
	assert(Type.is(tree, Type.Tree))
	assert(Type.is(toElement, Type.Element))

	tree.scheduler:schedule(taskReconcileNode({
		node = tree.rootNode,
		toElement = toElement,
	}))
end

return {
	mount = mountTree,
	unmount = unmountTree,
	reconcile = reconcileTree,
}