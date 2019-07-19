local IndentedOutput = {}
local IndentedOutputMetatable = {
	__index = IndentedOutput,
}

function IndentedOutput.new(indentation)
	indentation = indentation or 2

	local output = {
		_level = 0,
		_indentation = (" "):rep(indentation),
		_lines = {},
	}

	setmetatable(output, IndentedOutputMetatable)

	return output
end

function IndentedOutput:write(line, ...)
	if select("#", ...) > 0 then
		line = line:format(...)
	end

	local indentedLine = ("%s%s"):format(self._indentation:rep(self._level), line)

	table.insert(self._lines, indentedLine)
end

function IndentedOutput:push()
	self._level = self._level + 1
end

function IndentedOutput:pop()
	self._level = math.max(self._level - 1, 0)
end

function IndentedOutput:writeAndPush(line)
	self:write(line)
	self:push()
end

function IndentedOutput:popAndWrite(line)
	self:pop()
	self:write(line)
end

function IndentedOutput:join(separator)
	separator = separator or "\n"

	return table.concat(self._lines, separator)
end

return IndentedOutput
