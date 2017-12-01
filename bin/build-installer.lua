--[[
	Generates an install script using rbxpacker.

	It should be run from the project directory, like:

		lua bin/build-installer.lua
]]

os.exit(os.execute("rbxpacker --exclude **/*.spec.lua --folder Roact --name Roact lib LICENSE > installer.lua"))