#!/bin/sh

# Generates a release build of Roact with tests stripped.
#
# Usage from repo root:
# ./bin/build-release.sh

set -ev

rojo build -o Roact.rbxmx
remodel bin/strip-tests.lua Roact.rbxmx