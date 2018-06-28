*Portals* are a special kind of component provided by Roact that enable components to render objects into a separate, non-Roact Instance.

!!! info
	Eventually, there will be a diagram of Roact portals here. For now, just imagine Valve's hit game, *Portal*.

To create a portal, use the `Roact.Portal` component with `createElement`:

```lua
local function PartInWorkspace(props)
	return Roact.createElement(Roact.Portal, {
		target = Workspace
	}, {
		SomePart = Roact.createElement("Part", {
			Anchored = true
		})
	})
end
```

When we create `PartInWorkspace`, even if it's deep into our Roact tree, a `Part` Instance named `SomePart` will be created in `Workspace`.

!!! warning
	Portals should only be created to objects that aren't managed by Roact!

One particularly good use for portals is full-screen modal dialogs. When we render a modal dialog, we want it to take over the entire screen, but we want components deep in the tree to be able to create them!

```lua
local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

-- Our Modal component is a standard component, but with a portal at the top!
local function Modal(props)
	return Roact.createElement(Roact.Portal, {
		target = PlayerGui
	}, {
		Modal = Roact.createElement("ScreenGui", {}, {
			Label = Roact.createElement("TextButton", {
				Size = UDim2.new(1, 0, 1, 0),
				Text = "Click me to close!",

				[Roact.Event.Activated] = function()
					props.onClose()
				end
			})
		})
	})
end

-- A ModalButton contains a little bit of state to decide whether the dialog
-- should be open or not.
local ModalButton = Roact.Component:extend("ModalButton")

function ModalButton:init()
	self.state = {
		dialogOpen = false
	}
end

function ModalButton:render()
	local dialog = nil

	-- If the dialog isn't open, just avoid rendering it.
	if self.state.dialogOpen then
		dialog = Roact.createElement(Modal, {
			onClose = function()
				self:setState({
					dialogOpen = false
				})
			end
		})
	end

	return Roact.createElement("TextButton", {
		Size = UDim2.new(0, 400, 0, 300),
		Text = "Click me to open modal dialog!",

		[Roact.Event.Activated] = function()
			self:setState({
				dialogOpen = true
			})
		end
	}, {
		-- If `dialog` ends up nil, this line does nothing!
		Dialog = dialog
	})
end
```