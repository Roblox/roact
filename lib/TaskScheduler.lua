local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Type = require(script.Parent.Type)

local function DEBUG_showTask(task)
	if typeof(task) == "function" then
		return "<Task function>"
	elseif typeof(task) == "table" then
		return ("<Task %q>"):format(tostring(task.taskName))
	else
		return "<INVALID TASK>"
	end
end

local TaskScheduler = {}
TaskScheduler.prototype = {}
TaskScheduler.__index = TaskScheduler.prototype

local function getGuid()
	return HttpService:GenerateGUID(false)
end

function TaskScheduler.new(tree, isAsync, asyncBudgetMs)
	assert(Type.of(tree) == Type.Tree)
	assert(typeof(isAsync) == "boolean")
	assert(typeof(asyncBudgetMs) == "number")

	local self = {
		tasks = {},
		taskIndex = 1,
		tasksRunning = false,
		isAsync = isAsync,
		renderStepId = getGuid(),
		tree = tree,
		asyncBudgetMs = asyncBudgetMs,
	}

	setmetatable(self, TaskScheduler)

	if isAsync then
		RunService:BindToRenderStep(self.renderStepId, Enum.RenderPriority.Last.Value, function()
			self:processAsync()
		end)
	end

	return self
end

function TaskScheduler.prototype:destroy()
	if self.isAsync then
		RunService:UnbindFromRenderStep(self.renderStepId)
	end
end

function TaskScheduler.prototype:schedule(task)
	assert(typeof(task) == "function" or typeof(task) == "table")

	self.tasks[#self.tasks + 1] = task

	if not self.isAsync and not self.tasksRunning then
		self:processSync()
	end
end

function TaskScheduler.prototype:processSync()
	self.tasksRunning = true

	warn(("="):rep(80))
	print("Sync frame:", #self.tasks, "tasks in queue, marker at", self.taskIndex)

	local i = self.taskIndex
	while true do
		local task = self.tasks[i]

		if task == nil then
			self.tasks = {}
			self.taskIndex = 1

			print("Stopping sync frame: ran out of tasks")
			break
		end

		print("Running task", DEBUG_showTask(task))

		if typeof(task) == "function" then
			task(self.tree)
		else
			task:taskPerform(self.tree)
		end

		i = i + 1
	end

	self.tasksRunning = false
end

function TaskScheduler.prototype:processAsync()
	if #self.tasks == 0 then
		return
	end

	warn(("-"):rep(80))
	print("Async frame:", #self.tasks, "tasks in queue; marker at", self.taskIndex)

	self.tasksRunning = true

	local startTime = tick()
	local i = self.taskIndex
	while true do
		local task = self.tasks[i]

		local totalTimeElapsed = tick() - startTime

		if task == nil then
			self.tasks = {}
			self.taskIndex = 1

			print("Stopping async frame: ran out of tasks. Took", totalTimeElapsed * 1000, "ms")
			break
		end

		print("Running task", DEBUG_showTask(task))

		if typeof(task) == "function" then
			task(self.tree)
		else
			task:taskPerform(self.tree)
		end

		i = i + 1

		if totalTimeElapsed >= self.asyncBudgetMs then
			self.taskIndex = i

			print("Stopping async frame: ran out of time. Took", totalTimeElapsed * 1000, "ms")
			break
		end
	end

	self.tasksRunning = false
end

return TaskScheduler