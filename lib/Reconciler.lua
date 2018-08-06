--[[
	The reconciler uses the virtual DOM generated by components to create a real
	tree of Roblox instances.

	The reonciler has three basic operations:
	* mount (previously reify)
	* reconcile
	* unmount (previously teardown)

	Mounting is the process of creating new components. This is first
	triggered when the user calls `Roact.mount` on an element. This is where the
	structure of the component tree is built, later used and modified by the
	reconciliation and unmounting steps.

	Reconciliation accepts an existing concrete instance tree (created by mount)
	along with a new element that describes the desired tree. The reconciler
	will do the minimum amount of work required to update tree's components to
	match the new element, sometimes invoking mount to create new branches.

	Unmounting destructs for the tree. It will crawl through the tree,
	destroying nodes from the bottom up.

	Much of the reconciler's work is done by Component, which is the base for
	all stateful components in Roact. Components can trigger reconciliation (and
	implicitly, unmounting) via state updates that come with their own caveats.
]]

local Core = require(script.Parent.Core)
local Event = require(script.Parent.Event)
local Change = require(script.Parent.Change)
local getDefaultPropertyValue = require(script.Parent.getDefaultPropertyValue)
local SingleEventManager = require(script.Parent.SingleEventManager)
local Symbol = require(script.Parent.Symbol)
local GlobalConfig = require(script.Parent.GlobalConfig)

local isInstanceHandle = Symbol.named("isInstanceHandle")

local DEFAULT_SOURCE = "\n\t<Use Roact.setGlobalConfig with the 'elementTracing' key to enable detailed tracebacks>\n"

local ElementKind = {
	None = Symbol.named("ElementKind.None"),
	Portal = Symbol.named("ElementKind.Portal"),
	Primitive = Symbol.named("ElementKind.Primitive"),
	Functional = Symbol.named("ElementKind.Functional"),
	Stateful = Symbol.named("ElementKind.Stateful"),
}

--[[
	Sets the value of a reference to a new rendered object.
	Correctly handles both function-style and object-style refs.
]]
local function applyRef(ref, newRbx)
	if ref == nil then
		return
	end

	if type(ref) == "table" then
		ref.current = newRbx
	else
		ref(newRbx)
	end
end

local componentTypesToKinds = {
	["string"] = ElementKind.Primitive,
	["function"] = ElementKind.Functional,
	["table"] = ElementKind.Stateful,
}
local function getElementKind(element)
	local elementType = typeof(element)

	-- We ignore boolean values, which enables using a shorter syntax for
	-- conditionally rendered elements.
	if elementType == "nil" or elementType == "boolean" then
		return ElementKind.None
	end

	if elementType ~= "table" then
		return nil
	end

	local component = element.component

	if component == Core.Portal then
		return ElementKind.Portal
	end

	local componentType = typeof(component)

	return componentTypesToKinds[componentType]
end

local Reconciler = {}

Reconciler._singleEventManager = SingleEventManager.new()

--[[
	Destroy the given Roact instance, all of its descendants, and associated
	Roblox instances owned by the components.
]]
function Reconciler.unmount(instanceHandle)
	local element = instanceHandle._element

	local elementKind = getElementKind(element)

	if elementKind == ElementKind.Primitive then
		-- We're destroying a Roblox Instance-based object

		-- Kill refs before we make changes, since any mutations past this point
		-- aren't relevant to components.
		applyRef(element.props[Core.Ref], nil)

		for _, child in pairs(instanceHandle._children) do
			Reconciler.unmount(child)
		end

		-- Necessary to make sure SingleEventManager doesn't leak references
		Reconciler._singleEventManager:disconnectAll(instanceHandle._rbx)

		instanceHandle._rbx:Destroy()
	elseif elementKind == ElementKind.Functional then
		-- Functional components can return nil
		if instanceHandle._child then
			Reconciler.unmount(instanceHandle._child)
		end
	elseif elementKind == ElementKind.Stateful then
		instanceHandle._instance:_unmount()
	elseif elementKind == ElementKind.Portal then
		for _, child in pairs(instanceHandle._children) do
			Reconciler.unmount(child)
		end
	else
		error(("Cannot unmount invalid Roact instance %q"):format(tostring(element)))
	end
end

--[[
	Public interface to reifier. Hides parameters used when recursing down the
	component tree.
]]
function Reconciler.mount(element, parent, key)
	return Reconciler._mountInternal(element, parent, key)
end

--[[
	Instantiates components to represent the given element.

	Parameters:
		- `element`: The element to mount.
		- `parent`: The Roblox object to contain the contained instances
		- `key`: The Name to give the Roblox instance that gets created
		- `context`: Used to pass Roact context values down the tree

	The structure created by this method is important to the functionality of
	the reconciliation methods; they depend on this structure being well-formed.
]]
function Reconciler._mountInternal(element, parent, key, context)
	local elementKind = getElementKind(element)

	if elementKind == nil then
		error(("Cannot mount invalid Roact element %q"):format(tostring(element)))
	end

	if elementKind == ElementKind.Primitive then
		-- Primitive elements are backed directly by Roblox Instances.

		local rbx = Instance.new(element.component)

		-- Update Roblox properties
		for key, value in pairs(element.props) do
			Reconciler._setRbxProp(rbx, key, value, element)
		end

		-- Create children!
		local children = {}

		if element.props[Core.Children] then
			for key, childElement in pairs(element.props[Core.Children]) do
				local childInstance = Reconciler._mountInternal(childElement, rbx, key, context)

				children[key] = childInstance
			end
		end

		-- This name can be passed through multiple components.
		-- Elements with the same key will be treated as the same
		-- element between reconciles; the old element will be
		-- reconciled to the new element with the same key.
		if key then
			rbx.Name = key
		end

		rbx.Parent = parent

		-- Attach ref values, since the instance is initialized now.
		applyRef(element.props[Core.Ref], rbx)

		return {
			[isInstanceHandle] = true,
			_key = key,
			_parent = parent,
			_element = element,
			_context = context,
			_children = children,
			_rbx = rbx,
		}
	elseif elementKind == ElementKind.Functional then
		-- Functional elements contain 0 or 1 children.

		local instanceHandle = {
			[isInstanceHandle] = true,
			_key = key,
			_parent = parent,
			_element = element,
			_context = context,
		}

		local vdom = element.component(element.props)
		if vdom then
			instanceHandle._child = Reconciler._mountInternal(vdom, parent, key, context)
		end

		return instanceHandle
	elseif elementKind == ElementKind.Stateful then
		-- Stateful elements have 0 or 1 children, and also have a backing
		-- instance that can keep state.

		-- We separate the instance's implementation from our handle to it.
		local instanceHandle = {
			[isInstanceHandle] = true,
			_key = key,
			_parent = parent,
			_element = element,
			_child = nil,
		}

		local instance = element.component._new(element.props, context)

		instanceHandle._instance = instance
		instance:_mount(instanceHandle)

		return instanceHandle
	elseif elementKind == ElementKind.Portal then
		-- Portal elements have one or more children.

		local target = element.props.target
		if not target then
			error(("Cannot mount Portal without specifying a target."):format(tostring(element)))
		elseif typeof(target) ~= "Instance" then
			error(("Cannot mount Portal with target of type %q."):format(typeof(target)))
		end

		-- Create children!
		local children = {}

		if element.props[Core.Children] then
			for key, childElement in pairs(element.props[Core.Children]) do
				local childInstance = Reconciler._mountInternal(childElement, target, key, context)

				children[key] = childInstance
			end
		end

		return {
			[isInstanceHandle] = true,
			_key = key,
			_parent = parent,
			_element = element,
			_context = context,
			_children = children,
			_rbx = target,
		}
	elseif elementKind == ElementKind.None then
		return nil
	end

	error(("Unexpected element kind %s. This is a Roact bug."):format(tostring(elementKind)))
end

--[[
	A public interface around _reconcileInternal
]]
function Reconciler.reconcile(instanceHandle, newElement)
	if instanceHandle == nil or not instanceHandle[isInstanceHandle] then
		local message = (
			"Bad argument #1 to Reconciler.reconcile, expected component instance handle, found %s"
		):format(
			typeof(instanceHandle)
		)

		error(message, 2)
	end

	return Reconciler._reconcileInternal(instanceHandle, newElement)
end

--[[
	Applies the state given by newElement to an existing Roact instance.

	reconcile will return the instance that should be used. This instance can
	be different than the one that was passed in.
]]
function Reconciler._reconcileInternal(instanceHandle, newElement)
	local oldElement = instanceHandle._element

	local newElementKind = getElementKind(newElement)

	if newElementKind == nil then
		error(("Cannot reconcile to invalid Roact element %q"):format(tostring(newElement)))
	end

	if newElementKind == ElementKind.None then
		Reconciler.unmount(instanceHandle)

		return nil
	end

	-- If the element changes type, we assume its subtree will be substantially
	-- different. This lets us skip comparisons of a large swath of nodes.
	if oldElement.component ~= newElement.component then
		if GlobalConfig.getValue("warnOnTypeChange") then
			warn(("A Roact component is changing type from %s to %s during reconciliation!\n"
				.. "This can cause performance issues; see issue #88 for details."):format(
				tostring(oldElement.component),
				tostring(newElement.component)
			))

			print(("Old element source: %s\nNew element source: %s"):format(
				oldElement.source or DEFAULT_SOURCE,
				newElement.source or DEFAULT_SOURCE
			))
		end

		local parent = instanceHandle._parent
		local key = instanceHandle._key

		local context
		if getElementKind(oldElement) == ElementKind.Stateful then
			context = instanceHandle._instance._context
		else
			context = instanceHandle._context
		end

		Reconciler.unmount(instanceHandle)

		local newInstance = Reconciler._mountInternal(newElement, parent, key, context)

		return newInstance
	end

	if newElementKind == ElementKind.Primitive then
		local oldRef = oldElement.props[Core.Ref]
		local newRef = newElement.props[Core.Ref]

		-- Change the ref in one pass before applying any changes.
		-- Roact doesn't provide any guarantees with regards to the sequencing
		-- between refs and other changes in the commit phase.
		if newRef ~= oldRef then
			applyRef(oldRef, nil)
			applyRef(newRef, instanceHandle._rbx)
		end

		-- Update properties and children of the Roblox object.
		Reconciler._reconcilePrimitiveProps(oldElement, newElement, instanceHandle._rbx)
		Reconciler._reconcilePrimitiveChildren(instanceHandle, newElement)

		instanceHandle._element = newElement

		return instanceHandle
	elseif newElementKind == ElementKind.Functional then
		instanceHandle._element = newElement

		local rendered = newElement.component(newElement.props)
		local newChild

		if instanceHandle._child then
			-- Transition from tree to tree, even if 'rendered' is nil
			newChild = Reconciler._reconcileInternal(instanceHandle._child, rendered)
		elseif rendered then
			-- Transition from nil to new tree
			newChild = Reconciler._mountInternal(
				rendered,
				instanceHandle._parent,
				instanceHandle._key,
				instanceHandle._context
			)
		end

		instanceHandle._child = newChild

		return instanceHandle
	elseif newElementKind == ElementKind.Stateful then
		instanceHandle._element = newElement

		-- Stateful elements can take care of themselves.
		instanceHandle._instance:_update(newElement.props)

		return instanceHandle
	elseif newElementKind == ElementKind.Portal then
		if instanceHandle._rbx ~= newElement.props.target then
			local parent = instanceHandle._parent
			local key = instanceHandle._key
			local context = instanceHandle._context

			Reconciler.unmount(instanceHandle)

			local newInstance = Reconciler._mountInternal(newElement, parent, key, context)

			return newInstance
		end

		Reconciler._reconcilePrimitiveChildren(instanceHandle, newElement)

		instanceHandle._element = newElement

		return instanceHandle
	end

	error(("Unexpected element kind %s. This is a Roact bug."):format(tostring(newElementKind)))
end

--[[
	Reconciles the children of an existing Roact instance and the given element.
]]
function Reconciler._reconcilePrimitiveChildren(instance, newElement)
	local elementChildren = newElement.props[Core.Children]

	-- Reconcile existing children that were changed or removed
	for key, childInstance in pairs(instance._children) do
		local childElement = elementChildren and elementChildren[key]

		childInstance = Reconciler._reconcileInternal(childInstance, childElement)

		instance._children[key] = childInstance
	end

	-- Create children that were just added!
	if elementChildren then
		for key, childElement in pairs(elementChildren) do
			-- Update if we didn't hit the child in the previous loop
			if not instance._children[key] then
				local childInstance = Reconciler._mountInternal(childElement, instance._rbx, key, instance._context)
				instance._children[key] = childInstance
			end
		end
	end
end

--[[
	Reconciles the properties between two primitive Roact elements and applies
	the differences to the given Roblox object.
]]
function Reconciler._reconcilePrimitiveProps(fromElement, toElement, rbx)
	local seenProps = {}

	-- Set properties that were set with fromElement
	for key, oldValue in pairs(fromElement.props) do
		seenProps[key] = true

		local newValue = toElement.props[key]

		-- Assume any property that can be set to nil has a default value of nil
		if newValue == nil then
			local _, value = getDefaultPropertyValue(rbx.ClassName, key)

			-- We don't care if getDefaultPropertyValue fails, because
			-- _setRbxProp will catch the error below.
			newValue = value
		end

		-- Roblox does this check for normal values, but we have special
		-- properties like events that warrant this.
		if oldValue ~= newValue then
			Reconciler._setRbxProp(rbx, key, newValue, toElement)
		end
	end

	-- Set properties that are new in toElement
	for key, newValue in pairs(toElement.props) do
		if not seenProps[key] then
			seenProps[key] = true

			local oldValue = fromElement.props[key]

			if oldValue ~= newValue then
				Reconciler._setRbxProp(rbx, key, newValue, toElement)
			end
		end
	end
end

--[[
	Used in _setRbxProp to avoid creating a new closure for every property set.
]]
local function set(rbx, key, value)
	rbx[key] = value
end

--[[
	Sets a property on a Roblox object, following Roact's rules for special
	case properties.

	This function can throw a couple different errors. In the future, calls to
	_setRbxProp should be wrapped in a pcall to give better errors to the user.

	For that to be useful, we'll need to attach a 'source' property on every
	element, created using debug.traceback(), that points to where the element
	was created.
]]
function Reconciler._setRbxProp(rbx, key, value, element)
	if type(key) == "string" then
		-- Regular property

		local success, err = pcall(set, rbx, key, value)

		if not success then
			local source = element.source or DEFAULT_SOURCE

			local message = ("Failed to set property %s on primitive instance of class %s\n%s\n%s"):format(
				key,
				rbx.ClassName,
				err,
				source
			)

			error(message, 0)
		end
	elseif type(key) == "table" then
		-- Special property with extra data attached.

		if key.type == Event then
			Reconciler._singleEventManager:connect(rbx, key.name, value)
		elseif key.type == Change then
			Reconciler._singleEventManager:connectProperty(rbx, key.name, value)
		else
			local source = element.source or DEFAULT_SOURCE

			-- luacheck: ignore 6
			local message = ("Failed to set special property on primitive instance of class %s\nInvalid special property type %q\n%s"):format(
				rbx.ClassName,
				tostring(key.type),
				source
			)

			error(message, 0)
		end
	elseif type(key) ~= "userdata" then
		-- Userdata values are special markers, usually created by Symbol
		-- They have no data attached other than being unique keys

		local source = element.source or DEFAULT_SOURCE

		local message = ("Properties with a key type of %q are not supported\n%s"):format(
			type(key),
			source
		)

		error(message, 0)
	end
end

return Reconciler
