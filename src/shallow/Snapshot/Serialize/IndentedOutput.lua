local IndentedOutput = {}
local IndentedOutputMetatable = {
	__index = IndentedOutput,
}

function IndentedOutput.new(indentation, removeTrailingWhitespaces)
	indentation = indentation or 2
	if removeTrailingWhitespaces == nil then
		removeTrailingWhitespaces = true
	end

	local output = {
		_level = 0,
		_indentation = (" "):rep(indentation),
		_lines = {},
		_removeTrailingWhitespaces = removeTrailingWhitespaces,
	}

	setmetatable(output, IndentedOutputMetatable)

	return output
end

function IndentedOutput:write(line, ...)
	if select("#", ...) > 0 then
		line = line:format(...)
	end

	if self._removeTrailingWhitespaces and line == "" then
		table.insert(self._lines, line)
	else
		table.insert(self._lines, ("%s%s"):format(self._indentation:rep(self._level), line))
	end
end

function IndentedOutput:push()
	self._level = self._level + 1
end

function IndentedOutput:pop()
	self._level = math.max(self._level - 1, 0)
end

function IndentedOutput:writeAndPush(...)
	self:write(...)
	self:push()
end

function IndentedOutput:popAndWrite(...)
	self:pop()
	self:write(...)
end

function IndentedOutput:join(separator)
	separator = separator or "\n"

	return table.concat(self._lines, separator)
end

return IndentedOutput
