local Roact = require(script.Parent.Parent.Roact)

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