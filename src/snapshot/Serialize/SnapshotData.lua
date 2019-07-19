local AnonymousFunction = require(script.Parent.AnonymousFunction)
local ElementKind = require(script.Parent.Parent.Parent.ElementKind)
local Type = require(script.Parent.Parent.Parent.Type)

local function sortSerializedChildren(childA, childB)
	return childA.hostKey < childB.hostKey
end

local SnapshotData = {}

function SnapshotData.type(wrapperType)
	local typeData = {
		kind = wrapperType.kind,
	}

	if wrapperType.kind == ElementKind.Host then
		typeData.className = wrapperType.className
	elseif wrapperType.kind == ElementKind.Stateful then
		typeData.componentName = tostring(wrapperType.component)
	end

	return typeData
end

function SnapshotData.propValue(prop)
	local propType = type(prop)

	if propType == "string"
		or propType == "number"
		or propType == "boolean"
		or propType == "userdata"
	then
		return prop

	elseif propType == 'function' then
		return AnonymousFunction

	else
		error(("SnapshotData does not support prop with value %q (type %q)"):format(
			tostring(prop),
			propType
		))
	end
end

function SnapshotData.props(wrapperProps)
	local serializedProps = {}

	for key, prop in pairs(wrapperProps) do
		if type(key) == "string"
			or Type.of(key) == Type.HostChangeEvent
			or Type.of(key) == Type.HostEvent
		then
			serializedProps[key] = SnapshotData.propValue(prop)

		else
			error(("SnapshotData does not support prop with key %q (type: %s)"):format(
				tostring(key),
				type(key)
			))
		end
	end

	return serializedProps
end

function SnapshotData.children(children)
	local serializedChildren = {}

	for i=1, #children do
		local childWrapper = children[i]

		serializedChildren[i] = SnapshotData.wrapper(childWrapper)
	end

	table.sort(serializedChildren, sortSerializedChildren)

	return serializedChildren
end

function SnapshotData.wrapper(wrapper)
	return {
		type = SnapshotData.type(wrapper.type),
		hostKey = wrapper.hostKey,
		props = SnapshotData.props(wrapper.props),
		children = SnapshotData.children(wrapper:getChildren()),
	}
end

return SnapshotData
