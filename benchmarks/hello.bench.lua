local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Roact)

return {
	iterations = 100000,
	step = function()
		local hello = Roact.createElement("StringValue", {
			Value = "Hello, world!",
		})

		local handle = Roact.mount(hello)
		Roact.unmount(handle)
	end,
}