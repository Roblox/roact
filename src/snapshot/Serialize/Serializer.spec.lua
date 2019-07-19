return function()
	local AnonymousFunction = require(script.Parent.AnonymousFunction)
	local Change = require(script.Parent.Parent.Parent.PropMarkers.Change)
	local Event = require(script.Parent.Parent.Parent.PropMarkers.Event)
	local ElementKind = require(script.Parent.Parent.Parent.ElementKind)
	local IndentedOutput = require(script.Parent.IndentedOutput)
	local Serializer = require(script.Parent.Serializer)

	describe("type", function()
		it("should serialize host elements", function()
			local output = IndentedOutput.new()
			Serializer.type({
				kind = ElementKind.Host,
				className = "TextLabel",
			}, output)

			expect(output:join()).to.equal(
				   "type = {\n"
				.. "  kind = ElementKind.Host,\n"
				.. "  className = \"TextLabel\",\n"
				.. "},"
			)
		end)

		it("should serialize stateful elements", function()
			local output = IndentedOutput.new()
			Serializer.type({
				kind = ElementKind.Stateful,
				componentName = "SomeComponent",
			}, output)

			expect(output:join()).to.equal(
				   "type = {\n"
				.. "  kind = ElementKind.Stateful,\n"
				.. "  componentName = \"SomeComponent\",\n"
				.. "},"
			)
		end)

		it("should serialize function elements", function()
			local output = IndentedOutput.new()
			Serializer.type({
				kind = ElementKind.Function,
			}, output)

			expect(output:join()).to.equal(
				   "type = {\n"
				.. "  kind = ElementKind.Function,\n"
				.. "},"
			)
		end)
	end)

	describe("propKey", function()
		it("should serialize to a named dictionary field", function()
			local keys = {"foo", "foo1"}

			for i=1, #keys do
				local key = keys[i]
				local result = Serializer.propKey(key)

				expect(result).to.equal(key)
			end
		end)

		it("should serialize to a string value field to escape non-alphanumeric characters", function()
			local keys = {"foo.bar", "1foo"}

			for i=1, #keys do
				local key = keys[i]
				local result = Serializer.propKey(key)

				expect(result).to.equal('["' .. key .. '"]')
			end
		end)
	end)

	describe("propValue", function()
		it("should serialize strings", function()
			local result = Serializer.propValue("foo")

			expect(result).to.equal('"foo"')
		end)

		it("should serialize strings with \"", function()
			local result = Serializer.propValue('foo"bar')

			expect(result).to.equal('"foo\\"bar"')
		end)

		it("should serialize numbers", function()
			local result = Serializer.propValue(10.5)

			expect(result).to.equal("10.5")
		end)

		it("should serialize booleans", function()
			expect(Serializer.propValue(true)).to.equal("true")
			expect(Serializer.propValue(false)).to.equal("false")
		end)

		it("should serialize enum items", function()
			local result = Serializer.propValue(Enum.SortOrder.LayoutOrder)

			expect(result).to.equal("Enum.SortOrder.LayoutOrder")
		end)

		it("should serialize Color3", function()
			local result = Serializer.propValue(Color3.new(0.1, 0.2, 0.3))

			expect(result).to.equal("Color3.new(0.1, 0.2, 0.3)")
		end)

		it("should serialize UDim", function()
			local result = Serializer.propValue(UDim.new(1, 0.5))

			expect(result).to.equal("UDim.new(1, 0.5)")
		end)

		it("should serialize UDim2", function()
			local result = Serializer.propValue(UDim2.new(1, 0.5, 2, 2.5))

			expect(result).to.equal("UDim2.new(1, 0.5, 2, 2.5)")
		end)

		it("should serialize Vector2", function()
			local result = Serializer.propValue(Vector2.new(1.5, 0.3))

			expect(result).to.equal("Vector2.new(1.5, 0.3)")
		end)

		it("should serialize AnonymousFunction symbol", function()
			local result = Serializer.propValue(AnonymousFunction)

			expect(result).to.equal("AnonymousFunction")
		end)
	end)

	describe("props", function()
		it("should serialize an empty table", function()
			local output = IndentedOutput.new()
			Serializer.props({}, output)

			expect(output:join()).to.equal("props = {},")
		end)

		it("should serialize table fields", function()
			local output = IndentedOutput.new()
			Serializer.props({
				key = 8,
			}, output)

			expect(output:join()).to.equal("props = {\n  key = 8,\n},")
		end)

		it("should serialize Roact.Event", function()
			local output = IndentedOutput.new()
			Serializer.props({
				[Event.Activated] = AnonymousFunction,
			}, output)

			expect(output:join()).to.equal(
				   "props = {\n"
				.. "  [Roact.Event.Activated] = AnonymousFunction,\n"
				.. "},"
			)
		end)

		it("should serialize Roact.Change", function()
			local output = IndentedOutput.new()
			Serializer.props({
				[Change.Position] = AnonymousFunction,
			}, output)

			expect(output:join()).to.equal(
				   "props = {\n"
				.. "  [Roact.Change.Position] = AnonymousFunction,\n"
				.. "},"
			)
		end)
	end)

	describe("children", function()
		it("should serialize an empty table", function()
			local output = IndentedOutput.new()
			Serializer.children({}, output)

			expect(output:join()).to.equal("children = {},")
		end)

		it("should serialize children in an array", function()
			local snapshotData = {
				type = {
					kind = ElementKind.Function,
				},
				hostKey = "HostKey",
				props = {},
				children = {},
			}

			local childrenOutput = IndentedOutput.new()
			Serializer.children({snapshotData}, childrenOutput)

			local snapshotDataOutput = IndentedOutput.new()
			snapshotDataOutput:push()
			Serializer.snapshotData(snapshotData, snapshotDataOutput)

			local expectResult = "children = {\n" .. snapshotDataOutput:join() .. "\n},"
			expect(childrenOutput:join()).to.equal(expectResult)
		end)
	end)

	describe("snapshotDataContent", function()
		it("should serialize all fields", function()
			local snapshotData = {
				type = {
					kind = ElementKind.Function,
				},
				hostKey = "HostKey",
				props = {},
				children = {},
			}
			local output = IndentedOutput.new()
			Serializer.snapshotDataContent(snapshotData, output)

			expect(output:join()).to.equal(
				   "type = {\n"
				.. "  kind = ElementKind.Function,\n"
				.. "},\n"
				.. 'hostKey = "HostKey",\n'
				.. "props = {},\n"
				.. "children = {},"
			)
		end)
	end)

	describe("snapshotData", function()
		it("should wrap snapshotDataContent result between curly braces", function()
			local snapshotData = {
				type = {
					kind = ElementKind.Function,
				},
				hostKey = "HostKey",
				props = {},
				children = {},
			}
			local contentOutput = IndentedOutput.new()
			contentOutput:push()
			Serializer.snapshotDataContent(snapshotData, contentOutput)

			local output = IndentedOutput.new()
			Serializer.snapshotData(snapshotData, output)

			local expectResult = "{\n" .. contentOutput:join() .. "\n},"
			expect(output:join()).to.equal(expectResult)
		end)
	end)

	describe("firstSnapshotData", function()
		it("should return a function that returns a table", function()
			local result = Serializer.firstSnapshotData({
				type = {
					kind = ElementKind.Function,
				},
				hostKey = "HostKey",
				props = {},
				children = {},
			})

			local pattern = "^return function%(.-%).+return%s+{(.+)}%s+end$"
			expect(result:match(pattern)).to.be.ok()
		end)
	end)
end