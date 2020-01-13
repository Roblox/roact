#!/bin/sh

# Usage: ./bin/test-roblox-cli.sh

if [ ! -z ${LOCALAPPDATA+x} ]; then
	# Probably Windows, look for any Roblox installation in the default path.

	VERSIONS_FOLDER="$LOCALAPPDATA/Roblox/Versions"
	INSTALL=`find "$VERSIONS_FOLDER" -maxdepth 1 -name version-* | head -1`
	CONTENT="$INSTALL/content"
else
	# Probably macOS, look for Roblox Studio in its default path.

	CONTENT="/Applications/RobloxStudio.App/Contents/Resources/content"
fi

rojo build place.project.json -o TestPlace.rbxlx
roblox-cli run --load.place TestPlace.rbxlx --assetFolder "$CONTENT"