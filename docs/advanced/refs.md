# Refs
*Refs* grant access to the actual Instance objects that are created by Roact. They're an escape hatch for when something is difficult or impossible to correctly express with the Roact API.

!!! info
	Refs can only be used with primitive components.

## Refs in Action
To create a ref, pass a function prop with the key `Roact.Ref` when creating a primitive element.

For example, suppose we wanted to create a search bar that captured cursor focus when any part of it was clicked. We might use a component like this:
```lua
--[[
	A search bar with an icon and a text box that captures focus for its TextBox
	when its icon is clicked
 ]]
local SearchBar = Roact.Component:extend("SearchBar")

function SearchBar:init()
	-- Roact.createRef creates an object reference.
	-- This has a single property, `current`, that can be used to access the
	-- current Roblox instance.
	self.textBoxRef = Roact.createRef()
end

function SearchBar:captureFocus()
	local textBox = self.textBoxRef.current

	-- If we have a current instance, capture focus on it.
	-- current will be nil if the component hasn't been mounted yet, or it's
	-- being unmounted.
	if textBox then
		textBox:CaptureFocus()
	end
end

function SearchBar:render()
	-- Render our icon and text box side by side in a Frame
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 200, 0, 20),
	}, {
		SearchIcon = Roact.createElement("ImageButton", {
			Size = UDim2.new(0, 20, 0, 20),
			-- Handle click events on the icon
			[Roact.Event.MouseButton1Click] = function()
				self:captureFocus()
			end,
		}),

		SearchTextBox = Roact.createElement("TextBox", {
			Size = UDim2.new(0, 180, 0, 20),
			Position = UDim2.new(0, 20, 0, 0),
			-- We use Roact.Ref to get a reference to the underlying object
			-- Roact will set textBoxRef.current to the underlying object as
			-- part of the rendering process.
			[Roact.Ref] = self.textBoxRef,
		}),
	})
end
```
When a user clicks on the outer `ImageButton`, the `captureFocus` method will be called and the `TextBox` instance will get focus as if it had been clicked on directly.

## Functional Refs
Roact allows you to use functions as refs. The function will be called with the Roblox object that Roact creates. For example, this is the SearchBar component from above, modified to use functional refs instead of object refs:
```lua
--[[
	A search bar with an icon and a text box that captures focus for its TextBox
	when its icon is clicked
 ]]
local SearchBar = Roact.Component:extend("SearchBar")

function SearchBar:render()
	-- Render our icon and text box side by side in a Frame
	return Roact.createElement("Frame", {
		Size = UDim2.new(0, 200, 0, 20),
	}, {
		SearchIcon = Roact.createElement("ImageButton", {
			Size = UDim2.new(0, 20, 0, 20),
			-- Handle click events on the icon
			[Roact.Event.MouseButton1Click] = function()

				-- If our capture method is defined, trigger it
				if self.captureTextboxFocus then
					self.captureTextboxFocus()
				end
			end
		}),

		SearchTextBox = Roact.createElement("TextBox", {
			Size = UDim2.new(0, 180, 0, 20),
			Position = UDim2.new(0, 20, 0, 0),
			-- We use Roact.Ref to get a reference to the underlying object
			[Roact.Ref] = function(rbx)

				-- Set a callback function to give focus to the TextBox
				self.captureTextboxFocus = function()
					rbx:CaptureFocus()
				end
			end
		}),
	})
end
```
When a user clicks on the outer `ImageButton`, the `captureTextboxFocus` callback will be triggered and the `TextBox` instance will get focus as if it had been clicked on directly.

## Refs During Teardown

!!! warning
	When a component instance is destroyed or the ref property changes, `nil` will be passed to the old ref function!

```lua
local frame = Roact.createElement("Frame", {
	[Roact.Ref] = function(rbx)
		print("Ref was called with", rbx, "of type", typeof(rbx))
	end
})

local handle = Roact.mount(frame)

-- Output:
--     Ref was called with Frame of type Instance

Roact.unmount(handle)

-- In the output:
--     Ref was called with nil of type nil
```
