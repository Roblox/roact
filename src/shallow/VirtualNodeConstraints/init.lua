local Constraints = require(script.Constraints)

local function satisfiesAll(virtualNode, constraints)
	for constraint, value in pairs(constraints) do
		local constraintFunction = Constraints[constraint]

		if not constraintFunction(virtualNode, value) then
			return false
		end
	end

	return true
end

local function validate(constraints)
	for constraint in pairs(constraints) do
		assert(Constraints[constraint] ~= nil, ("unknown constraint %q"):format(constraint))
	end
end

return {
	satisfiesAll = satisfiesAll,
	validate = validate,
}