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

local function noop()
end

local emptyTimes = {}
local function getEmptyTime(iterations)
	if emptyTimes[iterations] ~= nil then
		return emptyTimes[iterations]
	end

	local startTime = tick()

	for _ = 1, iterations do
		noop()
	end

	local endTime = tick()

	local result = endTime - startTime
	emptyTimes[iterations] = result

	return result
end

local benchmarkModules = {}

findBenchmarkModules(script, benchmarkModules)

table.sort(benchmarkModules, function(a, b)
	return a.Name < b.Name
end)

local startMessage = (
	"Starting %d benchmarks..."
):format(
	#benchmarkModules
)
print(startMessage)
print()

for _, module in ipairs(benchmarkModules) do
	local benchmark = require(module)

	if benchmark.setup ~= nil then
		benchmark.setup()
	end
	local startTime = tick()
	local step = benchmark.step

	for i = 1, benchmark.iterations do
		step(i)
	end

	local endTime = tick()
	if benchmark.teardown ~= nil then
		benchmark.teardown()
	end

	local totalTime = (endTime - startTime) - getEmptyTime(benchmark.iterations)

	local message = (
		"Benchmark %s:\n\t(%d iterations) took %f s (%f ns/iteration)"
	):format(
		module.Name,
		benchmark.iterations,
		totalTime,
		1e9 * totalTime / benchmark.iterations
	)

	print(message)
	print()
end

print("Benchmarks complete!")