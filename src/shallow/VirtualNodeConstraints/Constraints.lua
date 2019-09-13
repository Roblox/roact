local RoactRoot = script.Parent.Parent.Parent

local ElementKind = require(RoactRoot.ElementKind)

local Constraints = setmetatable({}, {
	__index = function(self, unexpectedConstraint)
		error(("unknown constraint %q"):format(unexpectedConstraint))
	end,
})

function Constraints.className(virtualNode, className)
	local element = virtualNode.currentElement
	local isHost = ElementKind.of(element) == ElementKind.Host

	return isHost and element.component == className
end

function Constraints.component(virtualNode, expectComponentValue)
	return virtualNode.currentElement.component == expectComponentValue
end

function Constraints.props(virtualNode, propSubSet)
	local elementProps = virtualNode.currentElement.props

	for propKey, propValue in pairs(propSubSet) do
		if elementProps[propKey] ~= propValue then
			return false
		end
	end

	return true
end

function Constraints.hostKey(virtualNode, expectHostKey)
	return virtualNode.hostKey == expectHostKey
end

return Constraints