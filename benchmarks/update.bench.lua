local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Roact = require(ReplicatedStorage.Roact)

local tree

return {
	iterations = 100000,
	setup = function()
		tree = Roact.mount(Roact.createElement("StringValue", {
			Value = "Initial",
		}))
	end,
	teardown = function()
		Roact.unmount(tree)
	end,
	step = function(i)
		Roact.update(tree, Roact.createElement("StringValue", {
			Value = tostring(i),
		}))
	end,
}