local Change = {}

local changeMetatable = {
	__tostring = function(self)
		return ("ChangeListener(%s)"):format(self.name)
	end
}

setmetatable(Change, {
	__index = function(self, propertyName)
		local changeListener = {
			type = Change,
			name = propertyName
		}

		setmetatable(changeListener, changeMetatable)
		Change[propertyName] = changeListener

		return changeListener
	end,
})

return Change