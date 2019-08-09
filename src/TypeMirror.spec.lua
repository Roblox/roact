return function()
	local Type = require(script.Parent.Type)
	local Mirror = require(script.Parent.TypeMirror)
	local allowedTypes = {
		Type.Binding,
		Type.Element,
		Type.HostChangeEvent,
		Type.HostEvent,
		Type.StatefulComponentClass,
		Type.StatefulComponentInstance,
		Type.VirtualTree
	}

	describe("Type", function()
		it("should return a mirror of an internal type", function()
			local name = Type.nameOf(Type.Element)
			local mirroredType = Mirror.Type[name]
			expect(mirroredType).to.equal(Mirror.Type.Element)
		end)

		it("should not return the actual internal type", function()
			local name = Type.nameOf(Type.Element)
			local mirroredType = Mirror.Type[name]
			expect(mirroredType).to.never.equal(Type.Element)
		end)

		it("should include all allowed types", function()
			for _, type in ipairs(allowedTypes) do
				local name = Type.nameOf(type)
				local mirroredType = Mirror.Type[name]
				expect(mirroredType).to.be.ok()
			end
		end)

		it("should not include any other types", function()
			local name = Type.nameOf(Type.VirtualNode)
			local success = pcall(function()
				local _ = Mirror.Type[name]
			end)
			expect(success).to.equal(false)
		end)
	end)

	describe("typeOf", function()
		it("should return nil if the value is not a table", function()
			expect(Mirror.typeOf(1)).to.equal(nil)
			expect(Mirror.typeOf(true)).to.equal(nil)
			expect(Mirror.typeOf("test")).to.equal(nil)
			expect(Mirror.typeOf(print)).to.equal(nil)
		end)

		it("should return nil if the table has no type", function()
			expect(Mirror.typeOf({})).to.equal(nil)
		end)

		it("should return the assigned type", function()
			local test = {
				[Type] = Type.Element
			}

			expect(Mirror.typeOf(test)).to.equal(Mirror.Type.Element)
		end)
	end)
end