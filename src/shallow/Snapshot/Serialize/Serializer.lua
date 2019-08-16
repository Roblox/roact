local RoactRoot = script.Parent.Parent.Parent.Parent

local ElementKind = require(RoactRoot.ElementKind)
local Ref = require(RoactRoot.PropMarkers.Ref)
local Type = require(RoactRoot.Type)
local Markers = require(script.Parent.Markers)
local IndentedOutput = require(script.Parent.IndentedOutput)

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

function Serializer.tableKey(key)
	local keyType = type(key)

	if keyType == "string" and key:match("^%a%w+$") then
		return key
	else
		return ("[%s]"):format(Serializer.tableValue(key))
	end
end

function Serializer.number(value)
	local _, fraction = math.modf(value)

	if fraction == 0 then
		return ("%s"):format(tostring(value))
	else
		return ("%0.7f"):format(value):gsub("%.?0+$", "")
	end
end

function Serializer.tableValue(value)
	local valueType = typeof(value)

	if valueType == "string" then
		return ("%q"):format(value)

	elseif valueType == "number" then
		return Serializer.number(value)

	elseif valueType == "boolean" then
		return ("%s"):format(tostring(value))

	elseif valueType == "Color3" then
		return ("Color3.new(%s, %s, %s)"):format(
			Serializer.number(value.r),
			Serializer.number(value.g),
			Serializer.number(value.b)
		)

	elseif valueType == "EnumItem" then
		return ("%s"):format(tostring(value))

	elseif valueType == "Rect" then
		return ("Rect.new(%s, %s, %s, %s)"):format(
			Serializer.number(value.Min.X),
			Serializer.number(value.Min.Y),
			Serializer.number(value.Max.X),
			Serializer.number(value.Max.Y)
		)

	elseif valueType == "UDim" then
		return ("UDim.new(%s, %d)"):format(Serializer.number(value.Scale), value.Offset)

	elseif valueType == "UDim2" then
		return ("UDim2.new(%s, %d, %s, %d)"):format(
			Serializer.number(value.X.Scale),
			value.X.Offset,
			Serializer.number(value.Y.Scale),
			value.Y.Offset
		)

	elseif valueType == "Vector2" then
		return ("Vector2.new(%s, %s)"):format(
			Serializer.number(value.X),
			Serializer.number(value.Y)
		)

	elseif Type.of(value) == Type.HostEvent then
		return ("Roact.Event.%s"):format(value.name)

	elseif Type.of(value) == Type.HostChangeEvent then
		return ("Roact.Change.%s"):format(value.name)

	elseif value == Ref then
		return "Roact.Ref"

	else
		for markerName, marker in pairs(Markers) do
			if value == marker then
				return ("Markers.%s"):format(markerName)
			end
		end

		error(("Cannot serialize value %q of type %q"):format(
			tostring(value),
			valueType
		))
	end
end

function Serializer.getKeyTypeOrder(key)
	if type(key) == "string" then
		return 1
	elseif Type.of(key) == Type.HostEvent then
		return 2
	elseif Type.of(key) == Type.HostChangeEvent then
		return 3
	elseif key == Ref then
		return 4
	else
		return math.huge
	end
end

function Serializer.compareKeys(a, b)
	-- a and b are of the same type here, because Serializer.sortTableKeys
	-- will only use this function to compare keys of the same type
	if Type.of(a) == Type.HostEvent or Type.of(a) == Type.HostChangeEvent then
		return a.name < b.name
	else
		return a < b
	end
end

function Serializer.sortTableKeys(a, b)
	-- first sort by the type of key, to place string props, then Roact.Event
	-- events, Roact.Change events and the Ref
	local orderA = Serializer.getKeyTypeOrder(a)
	local orderB = Serializer.getKeyTypeOrder(b)

	if orderA == orderB then
		return Serializer.compareKeys(a, b)
	else
		return orderA < orderB
	end
end

function Serializer.table(tableKey, dict, output)
	if next(dict) == nil then
		output:write("%s = {},", tableKey)
		return
	end

	output:writeAndPush("%s = {", tableKey)

	local keys = {}

	for key in pairs(dict) do
		table.insert(keys, key)
	end

	table.sort(keys, Serializer.sortTableKeys)

	for i=1, #keys do
		local key = keys[i]
		local value = dict[key]
		local serializedKey = Serializer.tableKey(key)

		if type(value) == "table" then
			Serializer.table(serializedKey, value, output)
		else
			output:write("%s = %s,", serializedKey, Serializer.tableValue(value))
		end
	end

	output:popAndWrite("},")
end

function Serializer.props(props, output)
	Serializer.table("props", props, output)
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
	output:write("local Markers = dependencies.Markers")
	output:write("")
	output:writeAndPush("return {")

	Serializer.snapshotDataContent(snapshotData, output)

	output:popAndWrite("}")
	output:popAndWrite("end")

	return output:join()
end

return Serializer
