local Heapstack = {}
Heapstack.__index = Heapstack

local FIRST_TWO_LINES = "^[^\n]+\n[^\n]+\n"
local THIRD_LINE = FIRST_TWO_LINES .. "([^\n]+)"
local THIRD_LINE_ON = FIRST_TWO_LINES .. "(.+)"
local LINE_AND_MSG = "^([^:]+:%d+): (.+)"
local ADD_TAB_AND_NEWLINE = "\t%s\n"

function Heapstack.new(debug)
	return setmetatable(debug and {
		saveCurrentFrame = true,
		push = Heapstack.debugPush,
	} or {}, Heapstack)
end

function Heapstack:push(func, ...)
	-- Calls will be stored on the heap, where errors wont affect them.
	local frame = {
		func = func,
		count = select("#", ...),
		...
	}
	self[#self + 1] = frame
	return frame
end

function Heapstack:debugPush(func, ...)
	local frame = Heapstack.push(self, func, ...)
	frame.trace = debug.traceback()
	frame.parent = self.curFrame
end

function Heapstack:pop()
	self[#self] = nil
end

function Heapstack:resume()
	local topFrame = #self
	while topFrame > 0 do
		local frame = self[topFrame]

		-- The frame will be removed even if the call errors, making run() continue to the next call
		self[topFrame] = nil

		-- We can save the frame if we  need information from it when and error occures
		self.curFrame = self.saveCurrentFrame and frame

		-- The heapstack is postpended so it wont mess with method calls and can be easily omited from arguments if unused
		frame.func(unpack(frame, 1, frame.count))

		topFrame = #self
	end
end

function Heapstack:run()
	local success, result = pcall(self.resume, self)
	while not success do
		local trace, msg = self:getTrace(result)
		warn(msg)
		print(trace)
		success, result = pcall(self.resume, self)
	end
end

function Heapstack:getTrace(result)
	local frame = self.curFrame
	if not frame then
		return "<Enable this Heapstack's debug mode to enable detailed traces>"
	end

	local lines = {"Heapstack trace:"}
	local i = 2

	local msg
	if result then
		lines[2], msg = ADD_TAB_AND_NEWLINE:format(result):match(LINE_AND_MSG)
		if lines[2] then
			-- At times, a different error format will be used. I'm not sure in what cases or what formats,
			-- so I've added this in as a safety. TODO: remove this if statement
			i = 3
		else
			msg = result .. "\n"
		end
	end

	while frame.parent do
		-- Pull out the location of where Heapstack:push() was called
		lines[i] = frame.trace:match(THIRD_LINE):match(LINE_AND_MSG) or frame.trace:match(THIRD_LINE)
		frame = frame.parent
		i = i + 1
	end
	-- Include the rest of the last call's stack trace
	lines[i] = frame.trace:match(THIRD_LINE_ON)

	return table.concat(lines, "\n"), msg
end

return Heapstack