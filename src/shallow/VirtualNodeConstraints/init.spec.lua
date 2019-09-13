return function()
	local VirtualNodesConstraints = require(script.Parent)

	describe("validate", function()
		it("should throw when a constraint does not exist", function()
			local constraints = {
				hostKey = "Key",
				foo = "bar",
			}

			local function validateNotExistingConstraint()
				VirtualNodesConstraints.validate(constraints)
			end

			expect(validateNotExistingConstraint).to.throw()
		end)

		it("should not throw when all constraints exsits", function()
			local constraints = {
				hostKey = "Key",
				className = "Frame",
			}

			local function validateExistingConstraints()
				VirtualNodesConstraints.validate(constraints)
			end

			expect(validateExistingConstraints).never.to.throw()
		end)
	end)
end