local Core = require(script.Parent.Core)

local RunService = game:GetService("RunService")

local DEBUG_LOGS = true

local ASYNC_SCHEDULER = true
local ASYNC_BUDGET_PER_FRAME = 0 -- 12 / 1000

local TYPE = {}
local TYPE_TREE = {}
local TYPE_NODE = {}

local function DEBUG_warn(...)
	if DEBUG_LOGS then
		warn(...)
	end
end

local function DEBUG_print(...)
	if DEBUG_LOGS then
		print(...)
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

local function scheduleTask(tree, task)
	DEBUG_print("Scheduling task", DEBUG_showTask(task))

	tree.tasks[#tree.tasks + 1] = task

	if not ASYNC_SCHEDULER and not tree.tasksRunning then
		processTreeTasksSync(tree)
	end
end

local function runTask(tree, task)
	DEBUG_print("Running task", DEBUG_showTask(task))

	if typeof(task) == "function" then
		-- This is an escape hatch for informally specified tasks right now
		task()
	elseif task.type == "mount" then
		local element = task.element
		local key = task.key
		local parentRbx = task.parentRbx

		local instance = Instance.new(element.component)
		instance.Name = key

		for prop, value in pairs(element.props) do
			if prop == Core.Children then
				for childKey, childElement in pairs(value) do
					scheduleTask(tree, {
						type = "mount",
						element = childElement,
						parentRbx = instance,
						key = childKey,
					})
				end
			else
				instance[prop] = value
			end
		end

		scheduleTask(tree, function()
			instance.Parent = parentRbx

			if task.DEBUG_root then
				tree.DEBUG_instance = instance
			end
		end)
	elseif task.type == "reconcile" then
		local instance = task.instance
		local fromElement = task.fromElement
		local toElement = task.toElement

		local visitedProps = {}

		-- TODO: toElement is nil?

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
						local oldChildElement = oldValue[key]
						local DEBUG_childInstance = instance:FindFirstChild(key)

						-- TODO: What if oldValue[Core.Children] is nil?

						if oldChildElement == nil then
							warn("NYI: creating children in reconciler")
						elseif newChildElement ~= oldChildElement then
							DEBUG_print("\t\tScheduling reconcile of child", key)

							scheduleTask(tree, {
								type = "reconcile",
								fromElement = oldChildElement,
								toElement = newChildElement,
								instance = DEBUG_childInstance,
							})
						end
					end

					for key in pairs(oldValue) do
						local newChildElement = newValue[key]
						local DEBUG_childInstance = instance:FindFirstChild(key)

						if newChildElement == nil then
							DEBUG_print("\t\tScheduling unmount of child", key)
							scheduleTask(tree, {
								type = "unmount",
								instance = DEBUG_childInstance,
							})
						end
					end
				else
					DEBUG_print("\tSetting", prop, newValue)
					instance[prop] = newValue
				end
			end
		end

		for prop in pairs(fromElement.props) do
			if not visitedProps[prop] then
				instance[prop] = nil
			end
		end
	elseif task.type == "unmount" then
		local instance = task.instance

		instance:Destroy()

		-- TODO: expand
	else
		error("unknown task " .. task.type)
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

		if task == nil then
			tree.tasks = {}
			tree.taskIndex = 1

			DEBUG_print("Stopping async frame: ran out of tasks")
			break
		end

		runTask(tree, task)

		i = i + 1

		if tick() - startTime >= timeBudget then
			tree.taskIndex = i

			DEBUG_print("Stopping async frame: ran out of time")
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

		runTask(tree, task)

		i = i + 1
	end

	tree.tasksRunning = false
end

local function mountTree(element, parentRbx)
	local tree = {
		[TYPE] = TYPE_TREE,
		tasks = {},
		taskIndex = 1,
		tasksRunning = false,
		connections = {},
		mounted = true,
	}

	if ASYNC_SCHEDULER then
		RunService:BindToRenderStep("ahhhh", Enum.RenderPriority.Last.Value, function()
			processTreeTasksAsync(tree, ASYNC_BUDGET_PER_FRAME)
		end)
	end

	scheduleTask(tree, {
		type = "mount",
		element = element,
		parentRbx = parentRbx,
		key = "Roact Root",
		DEBUG_root = true,
	})

	return tree
end

local function unmountTree(tree)
	assert(tree[TYPE] == TYPE_TREE, "not a tree")
	assert(tree.mounted, "not mounted")

	tree.mounted = false

	-- TODO: Flush/cancel existing tasks and tear down asynchronously

	RunService:UnbindFromRenderStep("ahhhh")
end

local function reconcileTree(tree, fromElement, toElement)
	scheduleTask(tree, {
		type = "reconcile",
		instance = tree.DEBUG_instance,
		fromElement = fromElement,
		toElement = toElement,
	})
end

local function reconcileNode(node, fromElement, toElement)
	assert(node[TYPE] == TYPE_NODE, "not a node")
end

return {
	mount = mountTree,
	reconcileTree = reconcileTree
}