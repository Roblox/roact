local function debugAssert(condition, message)
	assert(condition, message .. " (This is probably a bug in Roact!)")
end

return debugAssert