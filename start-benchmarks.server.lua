-- Get the current time in seconds.
-- This will be folded into Lemur eventually (LPGhatguy/lemur#30)
local getCurrentTime
if tick then
	-- Roblox's 'tick' implementation
	getCurrentTime = tick
else
	-- LuaSocket's 'socket.gettime'
	local ok, socket = pcall(require, "socket")

	assert(ok, "LuaSocket is required to run benchmarks on non-Roblox platforms.")

	getCurrentTime = socket.gettime
end

--[[
	Locate all .bench.lua files in the given Roblox tree.
]]
local function findBenchmarkModules(root, moduleList)
	for _, child in ipairs(root:GetChildren()) do
		if child:IsA("ModuleScript") and child.Name:match("%.bench$") then
			table.insert(moduleList, child)
		end

		findBenchmarkModules(child, moduleList)
	end
end

local benchmarkModules = {}

findBenchmarkModules(game.ReplicatedStorage.Benchmarks, benchmarkModules)

local message = (
	"Starting %d benchmarks..."
):format(
	#benchmarkModules
)
print(message)

for _, module in ipairs(benchmarkModules) do
	local benchmark = require(module)

	if benchmark.setup then
		benchmark.setup()
	end
	local startTime = getCurrentTime()

	for i = 1, benchmark.iterations do
		benchmark.step(i)
	end

	local endTime = getCurrentTime()
	if benchmark.teardown then
		benchmark.teardown()
	end

	local message = (
		"Benchmark %s:\n\t(%d iterations) took %f s (%f ns/iteration)"
	):format(
		module.Name,
		benchmark.iterations,
		endTime - startTime,
		1e9 * (endTime - startTime) / benchmark.iterations
	)

	print(message)
end

print("Benchmarks complete!")