-- This script is meant for execution with Remodel:
-- https://github.com/rojo-rbx/remodel
--
-- Usage:
-- remodel bin/strip-tests.lua my-model.rbxmx

local inputFile = ...

local function stripSpecs(container)
	if container.Name:find("%.spec") ~= nil then
		container.Parent = nil
	else
		for _, child in ipairs(container:GetChildren()) do
			stripSpecs(child)
		end
	end
end

local model = remodel.readModelFile(inputFile)[1]

stripSpecs(model)

remodel.writeModelFile(model, inputFile)