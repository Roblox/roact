local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Type = require(script.Parent.Type)

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

		-- A map from component instances to data about the render, like the
		-- props, state, and context. This data can be modified up until the
		-- actual render occurs, and then it should be removed from this map.
		scheduledRenderData = {},

		-- A list of lists of 'render tasks', which can be performed to render
		-- and then commit an update to a node.
		--
		-- We generally want to iterate through the tasks by depth, only
		-- performing tasks deeper in the tree after ones higher in the tree
		-- have already been performed, since data changes always flow down the
		-- tree in Roact.
		--
		-- Care has to be taken to keep this table from becoming a sparse array,
		-- which can cause strange bugs.
		scheduledRenderTasksByDepth = {},
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

function RenderScheduler.prototype:process()
end

return RenderScheduler