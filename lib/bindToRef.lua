local Core = require(script.Parent.Core)

local bindingMetatable = {
	__tostring = function(self)
		return ("RoactBinding(%s)"):format(tostring(self.ref.current))
	end,
}

local function bindToRef(ref)
	return setmetatable({
		[Core.Binding] = true,
		ref = ref,
	}, bindingMetatable)
end

return bindToRef