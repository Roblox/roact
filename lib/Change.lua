--[[
	Change is used to generate special prop keys that can be used to connect to
	GetPropertyChangedSignal.

	Generally, Change is indexed by a Roblox property name:

		Roact.createElement("TextBox", {
			[Roact.Change.Text] = function(rbx)
				print("The TextBox", rbx, "changed text to", rbx.Text)
			end,
		})
]]

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