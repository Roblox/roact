local Core = require(script.Parent.Core)
local Type = require(script.Parent.Type)
local Symbol = require(script.Parent.Symbol)

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local DEFAULT_TREE_CONFIG = {
	useAsyncScheduler = true,
	asyncSchedulerBudgetPerFrameMs = 12 / 1000
}

local DEBUG_LOGS_ENABLED = true

-- Used to mark a child that is going to be mounted, but is not yet.
local MountingNode = Symbol.named("MountingNode")

local DEBUG_warn
local DEBUG_print

if DEBUG_LOGS_ENABLED then
	DEBUG_warn = warn
	DEBUG_print = print
else
	DEBUG_warn = function()
	end

	DEBUG_print = function()
	end
end

local processTreeTasksSync

local function DEBUG_showTask(task)
	if typeof(task) == "function" then
		return "<Task function>"
	elseif typeof(task) == "table" then
		return ("<Task %q>"):format(task.type)
	else
		return "<INVALID TASK>"
	end
end

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

local function getGuid()
	return HttpService:GenerateGUID(false)
end

local function scheduleTask(tree, task)
	DEBUG_print("Scheduling task", DEBUG_showTask(task))

	tree.tasks[#tree.tasks + 1] = task

	if not tree.config.useAsyncScheduler and not tree.tasksRunning then
		processTreeTasksSync(tree)
	end
end

local function taskMountNode(details)
	local element = details.element
	local key = details.key
	local parentNode = details.parentNode
	local parentRbx = details.parentRbx
	local isTreeRoot = details.isTreeRoot
	local nodeDepth = details.nodeDepth

	assert(Type.is(element, Type.Element))
	assert(typeof(key) == "string")
	assert(Type.is(parentNode, Type.Node) or typeof(parentNode) == "nil")
	assert(typeof(parentRbx) == "Instance" or typeof(parentRbx) == "nil")
	assert(typeof(isTreeRoot) == "boolean")
	assert(typeof(nodeDepth) == "number")

	return function(tree)
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

						scheduleTask(tree, taskMountNode({
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

			scheduleTask(tree, function()
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
	end
end

local function taskUnmountNode(details)
	local node = details.node

	assert(Type.is(node, Type.Node))

	return function(tree)
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
	end
end

local function taskReconcileNode(details)
	local node = details.node
	local toElement = details.toElement

	assert(Type.is(node, Type.Node))
	assert(Type.is(toElement, Type.Element))

	return function(tree)
		local fromElement = node.element

		-- TODO: Branch on kind of node
		-- TODO: Check if component type changed

		local visitedProps = {}

		for prop, newValue in pairs(toElement.props) do
			visitedProps[prop] = true
			local oldValue = fromElement.props[prop]

			DEBUG_print("Checking prop", prop, oldValue, newValue)

			if newValue == oldValue then
				DEBUG_print("\tProp is the same.")
			else
				if prop == Core.Children then
					DEBUG_print("\tReconciling children...")

					for key, newChildElement in pairs(newValue) do
						local childNode = node.children[key]

						local oldChildElement = oldValue[key]

						-- TODO: What if oldValue[Core.Children] is nil?

						if oldChildElement == nil then
							warn("NYI: creating children in reconciler")
						elseif newChildElement ~= oldChildElement then
							DEBUG_print("\t\tScheduling reconcile of child", key)

							scheduleTask(tree, taskReconcileNode({
								node = childNode,
								toElement = newChildElement,
							}))
						end
					end

					for key in pairs(oldValue) do
						local newChildElement = newValue[key]
						local childNode = node.children[key]

						if newChildElement == nil then
							DEBUG_print("\t\tScheduling unmount of child", key)
							scheduleTask(tree, taskUnmountNode({
								node = childNode,
							}))
						end
					end
				else
					DEBUG_print("\tSetting", prop, newValue)
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
	end
end

local function processTreeTasksAsync(tree, timeBudget)
	if #tree.tasks == 0 then
		return
	end

	DEBUG_warn(("-"):rep(80))
	DEBUG_print("Async frame:", #tree.tasks, "tasks in queue; marker at", tree.taskIndex)

	tree.tasksRunning = true

	local startTime = tick()
	local i = tree.taskIndex
	while true do
		local task = tree.tasks[i]

		local totalTimeElapsed = tick() - startTime

		if task == nil then
			tree.tasks = {}
			tree.taskIndex = 1

			print("Stopping async frame: ran out of tasks. Took", totalTimeElapsed * 1000, "ms")
			break
		end

		DEBUG_print("Running task", DEBUG_showTask(task))
		task(tree)

		i = i + 1

		if totalTimeElapsed >= timeBudget then
			tree.taskIndex = i

			print("Stopping async frame: ran out of time. Took", totalTimeElapsed * 1000, "ms")
			break
		end
	end

	tree.tasksRunning = false
end

function processTreeTasksSync(tree)
	tree.tasksRunning = true

	DEBUG_warn(("="):rep(80))
	DEBUG_print("Sync frame:", #tree.tasks, "tasks in queue, marker at", tree.taskIndex)

	local i = tree.taskIndex
	while true do
		local task = tree.tasks[i]

		if task == nil then
			tree.tasks = {}
			tree.taskIndex = 1

			DEBUG_print("Stopping sync frame: ran out of tasks")
			break
		end

		DEBUG_print("Running task", DEBUG_showTask(task))
		task(tree)

		i = i + 1
	end

	tree.tasksRunning = false
end

local function mountTree(element, parentRbx, key)
	assert(Type.is(element, Type.Element))
	assert(typeof(parentRbx) == "Instance" or parentRbx == nil)
	assert(typeof(key) == "string")

	-- TODO: Accept config parameter and typecheck values
	local config = makeConfigObject(DEFAULT_TREE_CONFIG)

	local tree = {
		[Type] = Type.Tree,

		-- A list of tasks pending to be executed in the tree. The task list
		-- takes the form of a double-ended queue, with 'push back' and 'pop
		-- front' as the only operations.
		tasks = {},
		taskIndex = 1,

		-- Denotes whether tasks are currently being processed, whether
		-- synchronously or asynchronously.
		tasksRunning = false,

		-- A map from component instances to data about the render, like the
		-- props, state, and context. This data can be modified up until the
		-- actual render occurs, and then it should be removed from this map.
		scheduledRenders = {},

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

	if tree.config.useAsyncScheduler then
		local budget = tree.config.asyncSchedulerBudgetPerFrameMs

		tree.renderStepId = getGuid()
		RunService:BindToRenderStep(tree.renderStepId, Enum.RenderPriority.Last.Value, function()
			processTreeTasksAsync(tree, budget)
		end)
	end

	scheduleTask(tree, taskMountNode({
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

	if tree.config.useAsyncScheduler then
		RunService:UnbindFromRenderStep(tree.renderStepId)
	end

	-- TODO: Flush/cancel existing tasks and unmount asynchronously?

	scheduleTask(tree, taskUnmountNode({
		node = tree.rootNode,
	}))

	-- For now, flush the entire tree and unmount synchronously
	processTreeTasksSync(tree)
end

local function reconcileTree(tree, toElement)
	assert(Type.is(tree, Type.Tree))
	assert(Type.is(toElement, Type.Element))

	scheduleTask(tree, taskReconcileNode({
		node = tree.rootNode,
		toElement = toElement,
	}))
end

return {
	mount = mountTree,
	unmount = unmountTree,
	reconcile = reconcileTree,
}