local getDefaultPropertyValue = require(script.Parent.getDefaultPropertyValue)
local SingleEventManager = require(script.Parent.SingleEventManager)
local Component = require(script.Parent.Component)
local Change = require(script.Parent.Change)
local Event = require(script.Parent.Event)
local Core = require(script.Parent.Core)

local MOUNT_NAME = "Unable to mount element with a name of type %s"
local MOUNT_ELEMENT = "Unable to mount element of type %s"
local MOUNT_COMPONENT = "Unable to mount component of type %s"
local PROP_SPECIAL = "Unable to set special properties of type %s"
local PROP_TYPE = "Unable to set properties of type %s"
local REF_TYPE = "Ref handlers of type %s are not supported"
local IS_COMPONENT = {
	string = "string";
	userdata = "userdata";
	table = "table";
	["function"] = "function";
}
local IS_CONCRETE = {
	string = true;
	userdata = true;
}
local IS_STATEFUL = {
	table = true;
}
local function NO_OP() end
local EMPTY = setmetatable({}, {__newindex = NO_OP})

local Element = Core.Element
local Parent = Core.Parent
local Name = Core.Name
local Rbx = Core.Rbx
local Children = Core.Children
local None = Core.None
local Ref = Core.Ref
local Context = Core.Context
local Target = Core.Target
local Update = Core.Update
local Unmount = Core.Unmount

local Reconciler = {}
Reconciler.eventManager = SingleEventManager.new()

local function applyRef(rbx, ref)
	local refType = type(ref)
	if refType == "table" then
		ref.current = rbx
	elseif refType == "function" then
		ref(rbx)
	elseif refType ~= "nil" then
		error(REF_TYPE:format(refType))
	end
end

local function diff(from, to)
	local result = {}
	for key, value in pairs(to) do
		if from[key] ~= value then
			result[key] = value
		end
	end

	for key in pairs(from) do
		if to[key] == nil then
			result[key] = None
		end
	end

	return result
end

local function setProps(instance, props, oldProps)
	local rbx = props[Target] or instance[Rbx] or Instance.new(instance[Component])
	if instance[Rbx] ~= rbx then
		instance[Rbx] = rbx
	end

	for prop, value in pairs(props) do
		local propType = type(prop)
		if propType == "string" then
			if value == None then
				value = getDefaultPropertyValue(rbx.ClassName, prop)
			end
			rbx[prop] = value
		elseif propType == "table" then
			if prop.type == Event then
				Reconciler.eventManager:connect(rbx, prop.name, value)
			elseif prop.type == Change then
				Reconciler.eventManager:connectProperty(rbx, prop.name, value)
			else
				error(PROP_SPECIAL:format(prop.type))
			end
		elseif propType == "userdata" then
			if prop == Ref then
				applyRef(nil, oldProps[prop])
				applyRef(rbx, value)
			end
		else
			error(PROP_TYPE:format(propType))
		end
	end

	if rbx.Name ~= instance[Name] then
		rbx.Name = instance[Name]
	end

	if rbx.Parent ~= instance[Parent][Rbx] then
		rbx.Parent = instance[Parent][Rbx]
	end
end

local StatelessVirtualComponent = {
	[Update] = function(instance, newElement)
		instance[Rbx] = instance[Parent][Rbx]
		instance[Element] = newElement
		return {newElement[Component](newElement)}
	end;
	[Unmount] = NO_OP;
}
StatelessVirtualComponent.__index = StatelessVirtualComponent

local StatelessConcreteComponent = {
	[Update] = function(instance, newElement)
		local oldElement = instance[Element]
		instance[Element] = newElement
		setProps(instance, diff(oldElement, newElement), oldElement)
		return newElement[Children] or EMPTY
	end;
	[Unmount] = function(instance)
		Reconciler.eventManager:disconnectAll(instance[Rbx])
		if not instance[Element][Target] then
			instance[Rbx]:Destroy()
		end
	end;
}
StatelessConcreteComponent.__index = StatelessConcreteComponent

function Reconciler.mount(element, parent, name, context, instance)
	assert(type(element) == "table", MOUNT_ELEMENT:format(type(element)))
	assert(type(name) == "string", MOUNT_NAME:format(type(name)))
	local componentType = assert(IS_COMPONENT[type(element)], MOUNT_COMPONENT:format(type(element)))

	parent = parent or EMPTY
	instance = instance or {}
	instance[Parent] = parent
	instance[Name] = name
	instance[Context] = context

	parent[name] = IS_STATEFUL[componentType]
		and Component.new(instance)
		or setmetatable(instance, IS_CONCRETE[componentType]
			and StatelessConcreteComponent
			or StatelessVirtualComponent)

	Reconciler.reconcile(instance, element)

	return instance
end

function Reconciler.unmount(instance)
	local element = instance[Element]
	local component = element[Component]
	local componentType = type(component)

	for childName, childInstance in pairs(instance) do
		if type(childName) == "string" then
			Reconciler.unmount(childInstance)
		end
	end

	instance[Unmount](instance)

	if componentType == "string" then
		instance[Rbx]:Destroy()
	end

	instance[Parent][instance[Name]] = nil
end

function Reconciler.remount(instance)
	local element = instance[Element]
	local parent = instance[Parent]
	local name = instance[Name]
	local context = instance[Context]

	Reconciler.unmount(instance)

	for key in pairs(instance) do
		instance[key] = nil
	end

	Reconciler.mount(element, parent, name, context, instance)
end

function Reconciler.reconcile(instance, element)
	if instance[Element][Component] ~= element[Component] then
		instance[Element] = element
		return Reconciler.remount(instance)
	end

	local children = instance[Update](instance, element)
	for childName, childElement in pairs(diff(instance, children)) do
		if type(childName) == "string" then
			local childInstance = instance[childName]
			if childElement == None then
				Reconciler.unmount(childInstance)
			elseif childInstance and childElement ~= false then
				Reconciler.reconcile(childInstance, childElement)
			else
				Reconciler.mount(childElement, instance, childName, instance[Context])
			end
		end
	end
end

return Reconciler

-- TODO:
	-- Component.new should set [Update] and [Unmount] on the instance
	-- [Update] should always return a table or EMPTY
	-- Primitive component property error handling
-- Perhaps I should run the tests? ...Nah...