local Core = require(script.Parent.Core)

return function(value)
	return typeof(value) == "table" and value[Core.Binding] == true
end