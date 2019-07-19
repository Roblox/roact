local AnonymousFunction = require(script.Parent.AnonymousFunction)
local ElementKind = require(script.Parent.Parent.Parent.ElementKind)
local IndentedOutput = require(script.Parent.IndentedOutput)
local Type = require(script.Parent.Parent.Parent.Type)

local function sortRoactEvents(a, b)
	return a.name < b.name
end

local Serializer = {}

function Serializer.kind(kind)
	if kind == ElementKind.Host then
		return "Host"
	elseif kind == ElementKind.Function then
		return "Function"
	elseif kind == ElementKind.Stateful then
		return "Stateful"
	else
		error(("Cannot serialize ElementKind %q"):format(tostring(kind)))
	end
end

function Serializer.type(data, output)
	output:writeAndPush("type = {")
	output:write("kind = ElementKind.%s,", Serializer.kind(data.kind))

	if data.className then
		output:write("className = %q,", data.className)
	elseif data.componentName then
		output:write("componentName = %q,", data.componentName)
	end

	output:popAndWrite("},")
end

function Serializer.propKey(key)
	if key:match("^%a%w+$") then
		return key
	else
		return ("[%q]"):format(key)
	end
end

function Serializer.propValue(prop)
	local propType = typeof(prop)

	if propType == "string" then
		return ("%q"):format(prop)

	elseif propType == "number" or propType == "boolean" then
		return ("%s"):format(tostring(prop))

	elseif propType == "Color3" then
		return ("Color3.new(%s, %s, %s)"):format(prop.r, prop.g, prop.b)

	elseif propType == "EnumItem" then
		return ("%s"):format(tostring(prop))

	elseif propType == "UDim" then
		return ("UDim.new(%s, %s)"):format(prop.Scale, prop.Offset)

	elseif propType == "UDim2" then
		return ("UDim2.new(%s, %s, %s, %s)"):format(
			prop.X.Scale,
			prop.X.Offset,
			prop.Y.Scale,
			prop.Y.Offset
		)

	elseif propType == "Vector2" then
		return ("Vector2.new(%s, %s)"):format(prop.X, prop.Y)

	elseif prop == AnonymousFunction then
		return "AnonymousFunction"

	else
		error(("Cannot serialize prop %q with value of type %q"):format(
			tostring(prop),
			propType
		))
	end
end

function Serializer.tableContent(dict, output)
	local keys = {}

	for key in pairs(dict) do
		table.insert(keys, key)
	end

	table.sort(keys)

	for i=1, #keys do
		local key = keys[i]
		output:write("%s = %s,", Serializer.propKey(key), Serializer.propValue(dict[key], output))
	end
end

function Serializer.props(props, output)
	if next(props) == nil then
		output:write("props = {},")
		return
	end

	local stringProps = {}
	local events = {}
	local changedEvents = {}

	output:writeAndPush("props = {")

	for key, value in pairs(props) do
		if type(key) == "string" then
			stringProps[key] = value

		elseif Type.of(key) == Type.HostEvent then
			table.insert(events, key)

		elseif Type.of(key) == Type.HostChangeEvent then
			table.insert(changedEvents, key)

		end
	end

	Serializer.tableContent(stringProps, output)
	table.sort(events, sortRoactEvents)
	table.sort(changedEvents, sortRoactEvents)

	for i=1, #events do
		local event = events[i]
		local serializedPropValue = Serializer.propValue(props[event], output)
		output:write("[Roact.Event.%s] = %s,", event.name, serializedPropValue)
	end

	for i=1, #changedEvents do
		local changedEvent = changedEvents[i]
		local serializedPropValue = Serializer.propValue(props[changedEvent], output)
		output:write("[Roact.Change.%s] = %s,", changedEvent.name, serializedPropValue)
	end

	output:popAndWrite("},")
end

function Serializer.children(children, output)
	if #children == 0 then
		output:write("children = {},")
		return
	end

	output:writeAndPush("children = {")

	for i=1, #children do
		Serializer.snapshotData(children[i], output)
	end

	output:popAndWrite("},")
end

function Serializer.snapshotDataContent(snapshotData, output)
	Serializer.type(snapshotData.type, output)
	output:write("hostKey = %q,", snapshotData.hostKey)
	Serializer.props(snapshotData.props, output)
	Serializer.children(snapshotData.children, output)
end

function Serializer.snapshotData(snapshotData, output)
	output:writeAndPush("{")
	Serializer.snapshotDataContent(snapshotData, output)
	output:popAndWrite("},")
end

function Serializer.firstSnapshotData(snapshotData)
	local output = IndentedOutput.new()
	output:writeAndPush("return function(dependencies)")
	output:write("local Roact = dependencies.Roact")
	output:write("local ElementKind = dependencies.ElementKind")
	output:write("local AnonymousFunction = dependencies.AnonymousFunction")
	output:write("")
	output:writeAndPush("return {")

	Serializer.snapshotDataContent(snapshotData, output)

	output:popAndWrite("}")
	output:popAndWrite("end")

	return output:join()
end

return Serializer
