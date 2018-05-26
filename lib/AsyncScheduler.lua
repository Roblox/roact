local RunService = game:GetService("RunService")

local AsyncScheduler = {}
AsyncScheduler.__index = AsyncScheduler

function AsyncScheduler.new(budget)
	local self = setmetatable({}, AsyncScheduler)

	self.tasks = {}
	self.startIndex = 1

	self.connection = RunService.Stepped:Connect(function()
		self:step(budget)
	end)

	return self
end

function AsyncScheduler:schedule(task)
	self.tasks[#self.tasks + 1] = task
end

function AsyncScheduler:destruct()
	self.connection:Disconnect()
end

function AsyncScheduler:step(budget)
	if #self.tasks == 0 then
		return
	end

	local startTime = tick()

	local i = self.startIndex
	while true do
		local task = self.tasks[i]
		i = i + 1

		if task == nil then
			self.tasks = {}
			self.startIndex = 1
			break
		end

		task()

		if tick() - startTime >= budget then
			self.startIndex = i
			break
		end
	end
end

function AsyncScheduler:flush()
	self:step(math.huge)
end

return AsyncScheduler