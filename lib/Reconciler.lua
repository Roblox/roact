--[[
	The reconciler uses the virtual DOM generated by components to create a real
	tree of Roblox instances.

	The reonciler has three basic modes of operation:
	* reification (public as 'reify')
	* reconciliation (private)
	* teardown (public)

	Reification is the process of creating new nodes in the tree. This is first
	triggered when the user calls `Roact.reify` on a root element. This is where
	the structure of the concrete tree is built, later used and modified by the
	reconciliation step.

	Reconciliation accepts an existing concrete instance tree (created by reify)
	along with a new element that describes the desired new state.
	The reconciler will do the minimum amount of work required to update the
	instances to match the new element, sometimes invoking the reifier to create
	new branches.

	Teardown is the destructor for the tree. It will crawl through the tree,
	destroying nodes in the correct order and invoking lifecycle methods.
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

local function isPortal(element)
	if type(element) ~= "table" then
		return false
	end

	return element.component == Core.Portal
end

local Reconciler = {}

Reconciler._traceFunction = print
Reconciler._singleEventManager = SingleEventManager.new()

--[[
	Is this element backed by a Roblox instance directly?
]]
local function isPrimitiveElement(element)
	if type(element) ~= "table" then
		return false
	end

	return type(element.component) == "string"
end

--[[
	Is this element defined by a pure function?
]]
local function isFunctionalElement(element)
	if type(element) ~= "table" then
		return false
	end

	return type(element.component) == "function"
end

--[[
	Is this element defined by a component class?
]]
local function isStatefulElement(element)
	if type(element) ~= "table" then
		return false
	end

	return type(element.component) == "table"
end

--[[
	Destroy the given Roact instance, all of its descendants, and associated
	Roblox instances owned by the components.
]]
function Reconciler.teardown(instanceHandle)
	local element = instanceHandle._element

	if isPrimitiveElement(element) then
		-- We're destroying a Roblox Instance-based object

		-- Kill refs before we make changes, since any mutations past this point
		-- aren't relevant to components.
		if element.props[Core.Ref] then
			element.props[Core.Ref](nil)
		end

		for _, child in pairs(instanceHandle._reifiedChildren) do
			Reconciler.teardown(child)
		end

		-- Necessary to make sure SingleEventManager doesn't leak references
		Reconciler._singleEventManager:disconnectAll(instanceHandle._rbx)

		instanceHandle._rbx:Destroy()
	elseif isFunctionalElement(element) then
		-- Functional components can return nil
		if instanceHandle._reified then
			Reconciler.teardown(instanceHandle._reified)
		end
	elseif isStatefulElement(element) then
		-- Stop the component from setting state in willUnmount or anywhere thereafter.
		instanceHandle._instance._canSetState = false

		-- Tell the component we're about to tear everything down.
		-- This gives it some notice!
		if instanceHandle._instance.willUnmount then
			instanceHandle._instance:willUnmount()
		end

		-- Stateful components can return nil from render()
		if instanceHandle._reified then
			Reconciler.teardown(instanceHandle._reified)
		end

		-- Cut our circular reference between the instance and its handle
		instanceHandle._instance = nil
	elseif isPortal(element) then
		for _, child in pairs(instanceHandle._reifiedChildren) do
			Reconciler.teardown(child)
		end
	else
		error(("Cannot teardown invalid Roact instance %q"):format(tostring(element)))
	end
end

--[[
	Public interface to reifier. Hides parameters used when recursing down the
	component tree.
]]
function Reconciler.reify(element, parent, key)
	return Reconciler._reifyInternal(element, parent, key)
end

--[[
	Instantiates components to represent the given element.

	Parameters:
		- `element`: The element to reify.
		- `parent`: The Roblox object to contain the contained instances
		- `key`: The Name to give the Roblox instance that gets created
		- `context`: Used to pass Roact context values down the tree
		- `parentElement`: Used for diagnostics. Refers to the parent Roact element.

	The structure created by this method is important to the functionality of
	the reconciliation methods; they depend on this structure being well-formed.
]]
function Reconciler._reifyInternal(element, parent, key, context, parentHandle)
	if isPrimitiveElement(element) then
		-- Primitive elements are backed directly by Roblox Instances.

		local rbx = Instance.new(element.component)

		-- This name can be passed through multiple components.
		-- What's important is the final Roblox Instance receives the name
		-- It's solely for debugging purposes; Roact doesn't use it.
		-- It must be set prior to children or property
		if key then
			rbx.Name = key
		end

		-- Start building the handle now, so it can be traced appropriately.
		local handle = {
			[isInstanceHandle] = true,
			_key = key,
			_parent = parent,
			_element = element,
			_context = context,
			_rbx = rbx,
		}

		-- Only set these properties if tracing is enabled, since that's what
		-- these are used for.
		if GlobalConfig.getValue("logAllMutations") then
			handle._parentHandle = parentHandle
		end

		-- Update Roblox properties
		for key, value in pairs(element.props) do
			-- Skip the Name key; it was already set.
			if key ~= "Name" then
				Reconciler._setRbxProp(rbx, key, value, element, handle)
			end
		end

		-- Create children!
		local reifiedChildren = {}

		if element.props[Core.Children] then
			for key, childElement in pairs(element.props[Core.Children]) do
				local childInstance = Reconciler._reifyInternal(childElement, rbx, key, context, handle)

				reifiedChildren[key] = childInstance
			end
		end

		rbx.Parent = parent

		-- Attach ref values, since the instance is initialized now.
		if element.props[Core.Ref] then
			element.props[Core.Ref](rbx)
		end

		handle._reifiedChildren = reifiedChildren
		return handle
	elseif isFunctionalElement(element) then
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
			instanceHandle._reified = Reconciler._reifyInternal(vdom, parent, key, context)
		end

		return instanceHandle
	elseif isStatefulElement(element) then
		-- Stateful elements have 0 or 1 children, and also have a backing
		-- instance that can keep state.

		-- We separate the instance's implementation from our handle to it.
		local instanceHandle = {
			[isInstanceHandle] = true,
			_key = key,
			_parent = parent,
			_element = element,
			_reified = nil,
		}

		local instance = element.component._new(element.props, context)

		instanceHandle._instance = instance
		instance:_reify(instanceHandle)

		return instanceHandle
	elseif isPortal(element) then
		-- Portal elements have one or more children.

		local target = element.props.target
		if not target then
			error(("Cannot reify Portal without specifying a target."):format(tostring(element)))
		elseif typeof(target) ~= "Instance" then
			error(("Cannot reify Portal with target of type %q."):format(typeof(target)))
		end

		-- Create children!
		local reifiedChildren = {}

		if element.props[Core.Children] then
			for key, childElement in pairs(element.props[Core.Children]) do
				local childInstance = Reconciler._reifyInternal(childElement, target, key, context)

				reifiedChildren[key] = childInstance
			end
		end

		return {
			[isInstanceHandle] = true,
			_key = key,
			_parent = parent,
			_element = element,
			_context = context,
			_reifiedChildren = reifiedChildren,
			_rbx = target,
		}
	elseif typeof(element) == "boolean" then
		-- Ignore booleans of either value
		-- See https://github.com/Roblox/roact/issues/14
		return nil
	end

	error(("Cannot reify invalid Roact element %q"):format(tostring(element)))
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

	-- Instance was deleted!
	if not newElement then
		Reconciler.teardown(instanceHandle)

		return nil
	end

	-- If the element changes type, we assume its subtree will be substantially
	-- different. This lets us skip comparisons of a large swath of nodes.
	if oldElement.component ~= newElement.component then
		local parent = instanceHandle._parent
		local key = instanceHandle._key

		local context
		if isStatefulElement(oldElement) then
			context = instanceHandle._instance._context
		else
			context = instanceHandle._context
		end

		Reconciler.teardown(instanceHandle)

		local newInstance = Reconciler._reifyInternal(newElement, parent, key, context)

		return newInstance
	end

	if isPrimitiveElement(newElement) then
		-- Roblox Instance change

		local oldRef = oldElement[Core.Ref]
		local newRef = newElement[Core.Ref]
		local refChanged = (oldRef ~= newRef)

		-- Cancel the old ref before we make changes. Apply the new one after.
		if refChanged and oldRef then
			oldRef(nil)
		end

		-- Update properties and children of the Roblox object.
		Reconciler._reconcilePrimitiveProps(oldElement, newElement, instanceHandle._rbx)
		Reconciler._reconcilePrimitiveChildren(instanceHandle, newElement)

		instanceHandle._element = newElement

		-- Apply the new ref if there was a ref change.
		if refChanged and newRef then
			newRef(instanceHandle._rbx)
		end

		return instanceHandle
	elseif isFunctionalElement(newElement) then
		instanceHandle._element = newElement

		local rendered = newElement.component(newElement.props)
		local newChild

		if instanceHandle._reified then
			-- Transition from tree to tree, even if 'rendered' is nil
			newChild = Reconciler._reconcileInternal(instanceHandle._reified, rendered)
		elseif rendered then
			-- Transition from nil to new tree
			newChild = Reconciler._reifyInternal(
				rendered,
				instanceHandle._parent,
				instanceHandle._key,
				instanceHandle._context
			)
		end

		instanceHandle._reified = newChild

		return instanceHandle
	elseif isStatefulElement(newElement) then
		instanceHandle._element = newElement

		-- Stateful elements can take care of themselves.
		instanceHandle._instance:_update(newElement.props)

		return instanceHandle
	elseif isPortal(newElement) then
		if instanceHandle._rbx ~= newElement.props.target then
			local parent = instanceHandle._parent
			local key = instanceHandle._key
			local context = instanceHandle._context

			Reconciler.teardown(instanceHandle)

			local newInstance = Reconciler._reifyInternal(newElement, parent, key, context)

			return newInstance
		end

		Reconciler._reconcilePrimitiveChildren(instanceHandle, newElement)

		instanceHandle._element = newElement

		return instanceHandle
	end

	error(("Cannot reconcile to match invalid Roact element %q"):format(tostring(newElement)))
end

--[[
	Reconciles the children of an existing Roact instance and the given element.
]]
function Reconciler._reconcilePrimitiveChildren(instance, newElement)
	local elementChildren = newElement.props[Core.Children]

	-- Reconcile existing children that were changed or removed
	for key, childInstance in pairs(instance._reifiedChildren) do
		local childElement = elementChildren and elementChildren[key]

		childInstance = Reconciler._reconcileInternal(childInstance, childElement)

		instance._reifiedChildren[key] = childInstance
	end

	-- Create children that were just added!
	if elementChildren then
		for key, childElement in pairs(elementChildren) do
			-- Update if we didn't hit the child in the previous loop
			if not instance._reifiedChildren[key] then
				local childInstance = Reconciler._reifyInternal(childElement, instance._rbx, key, instance._context)
				instance._reifiedChildren[key] = childInstance
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
	Computes a full name, even if the element is not parented to the DataModel yet.
]]
local function computeFullName(handle, rbx)
	-- If the instance is already parented, just use GetFullName.
	if rbx.Parent then
		return rbx:GetFullName()
	-- If the instance doesn't have a parent, it's still being reified, so we
	-- need to build the full name manually.
	else
		local fullName = rbx.Name
		local level = handle._parentHandle

		-- For the case of root elements, they have no _parent element, but they
		-- do have a _rbxParent, which is the parent that the root is being reified to.
		if not level then
			fullName = handle._parent:GetFullName() .. "." .. fullName
		end

		while level do
			local rbx = level._rbx
			fullName = rbx.Name .. "." .. fullName

			local nextLevel = level._parentHandle
			-- If there is a _parent element, travel through it.
			if nextLevel then
				level = nextLevel
			-- Otherwise, we've reached the root element of this element tree.
			-- Use the _rbxParent value and stop the loop.
			else
				fullName = level._parent:GetFullName() .. "." .. fullName
				break
			end
		end

		return fullName
	end
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
function Reconciler._setRbxProp(rbx, key, value, element, handle)
	if type(key) == "string" then
		-- Regular property

		local success, err = pcall(set, rbx, key, value)

		if GlobalConfig.getValue("logAllMutations") then
			local message = ("<TRACE> Setting %s on %s of class %s to %s"):format(
				key,
				computeFullName(handle, rbx),
				rbx.ClassName,
				tostring(value)
			)

			Reconciler._traceFunction(message)
		end

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

			if GlobalConfig.getValue("logAllMutations") then
				local message = ("<TRACE> Connecting function to event %s on %s of class %s"):format(
					key.name,
					computeFullName(handle, rbx),
					rbx.ClassName
				)

				Reconciler._traceFunction(message)
			end
		elseif key.type == Change then
			Reconciler._singleEventManager:connectProperty(rbx, key.name, value)

			if GlobalConfig.getValue("logAllMutations") then
				local message = ("<TRACE> Connecting function to property change event %s on %s of class %s"):format(
					key.name,
					computeFullName(handle, rbx),
					rbx.ClassName
				)

				Reconciler._traceFunction(message)
			end
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
