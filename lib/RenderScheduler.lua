local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Type = require(script.Parent.Type)
local BucketedPriorityQueue = require(script.Parent.BucketedPriorityQueue)

local function getGuid()
	return HttpService:GenerateGUID(false)
end

local RenderScheduler = {}
RenderScheduler.prototype = {}
RenderScheduler.__index = RenderScheduler.prototype

function RenderScheduler.new(tree, isAsync, asyncBudgetPerFrameMs)
	assert(Type.of(tree) == Type.Tree)
	assert(typeof(isAsync) == "boolean")
	assert(typeof(asyncBudgetPerFrameMs) == "number")

	local self = {
		tree = tree,
		isAsync = isAsync,
		asyncBudgetPerFrameMs = asyncBudgetPerFrameMs,
		renderStepId = getGuid(),

		-- A map from nodes to data about the render, like the props, state, and
		-- context. This data can be modified up until the actual render occurs,
		-- and then it should be removed from this map.
		scheduledRenderData = {},

		-- A priority queue of 'render tasks' which can be performed to render
		-- and commit an update to a node.
		--
		-- The priority of a task is equal to its depth in the tree so that
		-- shallower nodes will always be rendered first.
		scheduledRenderTasksByDepth = BucketedPriorityQueue.new(),
	}

	setmetatable(self, RenderScheduler)

	if isAsync then
		RunService:BindToRenderStep(self.renderStepId, Enum.RenderPriority.Last.Value, function()
			self:processAsync()
		end)
	end

	return self
end

function RenderScheduler.prototype:destroy()
	if self.isAsync then
		RunService:UnbindFromRenderStep(self.renderStepId)
	end
end

function RenderScheduler.prototype:scheduleMount()
end

function RenderScheduler.prototype:schedule(node, newData)
	assert(Type.of(node) == Type.Node)
	assert(typeof(newData) == "table")

	local newProps = newData.props
	local newState = newData.state
	local newContext = newData.context

	assert(typeof(newProps) == "table" or newProps == nil)
	assert(typeof(newState) == "table" or newState == nil)
	assert(typeof(newContext) == "table" or newContext == nil)
end

function RenderScheduler.prototype:processSync()
	while true do
		local task = self.scheduledRenderTasksByDepth:pop()

		if task == nil then
			break
		end

		task()
	end
end

function RenderScheduler.prototype:processAsync()
	error("NYI")
end

return RenderScheduler