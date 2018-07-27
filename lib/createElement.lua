local Core = require(script.Parent.Core)
local GlobalConfig = require(script.Parent.GlobalConfig)
local Type = require(script.Parent.Type)
local ElementKind = require(script.Parent.ElementKind)

--[[
	Creates a new element representing the given component.

	Elements are lightweight representations of what a component instance should
	look like.

	Children is a shorthand for specifying `Roact.Children` as a key inside
	props. If specified, the passed `props` table is mutated!
]]
local function createElement(component, props, children)
	assert(typeof(props) == "table" or props == nil, "`props` must be a table or nil")
	assert(typeof(children) == "table" or children == nil, "`children` must be a table or nil")

	if component == nil then
		error(("Expected component as an argument to createElement!"), 2)
	end

	if props == nil then
		props = {}
	end

	if children ~= nil then
		if props[Core.Children] ~= nil then
			warn("props[Children] was defined but was overridden by third parameter to createElement!")
		end

		props[Core.Children] = children
	end

	local elementKind = ElementKind.fromComponent(component)

	local element = {
		[Type] = Type.Element,
		[ElementKind] = elementKind,
		component = component,
		props = props,
	}

	if GlobalConfig.getValue("elementTracing") then
		element.source = ("\n%s\n"):format(debug.traceback())
	end

	return element
end

return createElement