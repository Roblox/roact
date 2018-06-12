local Type = require(script.Parent.Type)

local RenderScheduler = {}
RenderScheduler.__index = RenderScheduler

function RenderScheduler:new()
	local instance = {
		scheduledRendersByDepth = {},
	}

	setmetatable(instance, self)

	return instance
end

function RenderScheduler:schedule(node, newData)
	assert(Type.of(node) == Type.Node)
	assert(typeof(newData) == "table")

	local newProps = newData.props
	local newState = newData.state
	local newContext = newData.context

	assert(typeof(newProps) == "table" or newProps == nil)
	assert(typeof(newState) == "table" or newState == nil)
	assert(typeof(newContext) == "table" or newContext == nil)
end

return RenderScheduler