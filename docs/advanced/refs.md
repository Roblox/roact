# Refs
*Refs* grant access to the actual Instance objects that are created by Roact. They're an escape hatch for when something is difficult or impossible to correctly express with the Roact API.

!!! info
	Refs can only be used with primitive components.

## Refs in Action

To create a ref, pass a function prop with the key `Roact.Ref` when creating a primitive element.  Suppose we wanted to create a search bar that captured cursor focus when any part of it was clicked. We might use a component like this:

```lua
--[[ A search bar with an icon and a text box that captures focus for 
 its TextBox when it's icon is clicked ]]
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

local handle = Roact.reify(frame)

-- Output:
--     Ref was called with Frame of type Instance

Roact.teardown(handle)

-- In the output:
--     Ref was called with nil of type nil
```
