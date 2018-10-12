--[[
	Provides an API for acquiring a reference to a reified object. This
	API is designed to mimic React 16.3's createRef API.

	See:
	* https://reactjs.org/docs/refs-and-the-dom.html
	* https://reactjs.org/blog/2018/03/29/react-v-16-3.html#createref-api
]]
local createSignal = require(script.Parent.createSignal)

local refMetatable = {
	__tostring = function(self)
		return ("RoactReference(%s)"):format(tostring(self.current))
	end,
}

local Ref = {}

--[[
	Creates a ref object to be associated with an rbx. This is the only
	function of Ref that is needed by users
]]
function Ref.create()
	return setmetatable({
		current = nil,
		changed = createSignal(),
	}, refMetatable)
end

--[[

]]
function Ref.isRef(value)
	return typeof(value) == "table" and getmetatable(value) == refMetatable
end

--[[
	Sets the value of a reference to a new rendered object.
	Correctly handles both function-style and object-style refs.
]]
function Ref.apply(ref, newRbx)
	if ref == nil then
		return
	end

	if type(ref) == "table" then
		ref.current = newRbx
		ref.changed:fire(newRbx)
	else
		ref(newRbx)
	end
end

return Ref