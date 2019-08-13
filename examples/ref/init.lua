return function()
	local PlayerGui = game:GetService("Players").LocalPlayer.PlayerGui

	local Roact = require(game.ReplicatedStorage.Roact)

	--[[
		A search bar with an icon and a text box
		When the icon is clicked, the TextBox captures focus
	]]
	local SearchBar = Roact.Component:extend("SearchBar")

	function SearchBar:init()
		self.textBoxRef = Roact.createRef()
	end

	function SearchBar:render()
		return Roact.createElement("Frame", {
			Size = UDim2.new(0, 300, 0, 50),
			Position = UDim2.new(0.5, 0, 0.5, 0),
			AnchorPoint = Vector2.new(0.5, 0.5),
		}, {
			SearchIcon = Roact.createElement("TextButton", {
				Size = UDim2.new(0, 50, 0, 50),
				AutoButtonColor = false,
				Text = "=>",

				-- Handle click events on the search button
				[Roact.Event.Activated] = function()
					print("Button clicked; have the TextBox capture focus")
					self.textBoxRef:getValue():CaptureFocus()
				end,
			}),

			SearchTextBox = Roact.createElement("TextBox", {
				Size = UDim2.new(1, -50, 1, 0),
				Position = UDim2.new(0, 50, 0, 0),

				-- Use Roact.Ref to get a reference to the underlying object
				[Roact.Ref] = self.textBoxRef,
			}),
		})
	end

	local app = Roact.createElement("ScreenGui", nil, {
		SearchBar = Roact.createElement(SearchBar),
	})

	local handle = Roact.mount(app, PlayerGui)

	local function stop()
		Roact.unmount(handle)
	end

	return stop
end
