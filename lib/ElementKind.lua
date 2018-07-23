local Symbol = require(script.Parent.Symbol)
local strict = require(script.Parent.strict)

local ElementKind = strict {
	Portal = Symbol.named("ElementKind.Portal"),
	Primitive = Symbol.named("ElementKind.Primitive"),
	Functional = Symbol.named("ElementKind.Functional"),
	Stateful = Symbol.named("ElementKind.Stateful"),
}

return ElementKind