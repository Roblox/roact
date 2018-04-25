local Roact = require(script.Parent.Parent.Roact)

return {
	iterations = 100000,
	step = function()
		local hello = Roact.createElement("StringValue", {
			Value = "Hello, world!",
		})

		local handle = Roact.reify(hello)
		Roact.teardown(handle)
	end,
}