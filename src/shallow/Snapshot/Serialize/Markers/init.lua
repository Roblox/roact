local RoactRoot = script.Parent.Parent.Parent.Parent

local strict = require(RoactRoot.strict)

return strict({
	AnonymousFunction = require(script.AnonymousFunction),
	EmptyRef = require(script.EmptyRef),
	Signal = require(script.Signal),
	Unknown = require(script.Unknown),
}, "Markers")