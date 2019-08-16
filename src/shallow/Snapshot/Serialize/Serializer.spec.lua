return function()
	local RoactRoot = script.Parent.Parent.Parent.Parent

	local Markers = require(script.Parent.Markers)
	local Change = require(RoactRoot.PropMarkers.Change)
	local Event = require(RoactRoot.PropMarkers.Event)
	local ElementKind = require(RoactRoot.ElementKind)
	local IndentedOutput = require(script.Parent.IndentedOutput)
	local Ref = require(RoactRoot.PropMarkers.Ref)
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

	describe("tableKey", function()
		it("should serialize to a named dictionary field", function()
			local keys = {"foo", "foo1"}

			for i=1, #keys do
				local key = keys[i]
				local result = Serializer.tableKey(key)

				expect(result).to.equal(key)
			end
		end)

		it("should serialize to a string value field to escape non-alphanumeric characters", function()
			local keys = {"foo.bar", "1foo"}

			for i=1, #keys do
				local key = keys[i]
				local result = Serializer.tableKey(key)

				expect(result).to.equal('["' .. key .. '"]')
			end
		end)
	end)

	describe("number", function()
		it("should format integers", function()
			expect(Serializer.number(1)).to.equal("1")
			expect(Serializer.number(0)).to.equal("0")
			expect(Serializer.number(10)).to.equal("10")
		end)

		it("should minimize floating points zeros", function()
			expect(Serializer.number(1.2)).to.equal("1.2")
			expect(Serializer.number(0.002)).to.equal("0.002")
			expect(Serializer.number(5.5001)).to.equal("5.5001")
		end)

		it("should keep only 7 decimals", function()
			expect(Serializer.number(0.123456789)).to.equal("0.1234568")
			expect(Serializer.number(0.123456709)).to.equal("0.1234567")
		end)
	end)

	describe("tableValue", function()
		it("should serialize strings", function()
			local result = Serializer.tableValue("foo")

			expect(result).to.equal('"foo"')
		end)

		it("should serialize strings with \"", function()
			local result = Serializer.tableValue('foo"bar')

			expect(result).to.equal('"foo\\"bar"')
		end)

		it("should serialize numbers", function()
			local result = Serializer.tableValue(10.5)

			expect(result).to.equal("10.5")
		end)

		it("should serialize booleans", function()
			expect(Serializer.tableValue(true)).to.equal("true")
			expect(Serializer.tableValue(false)).to.equal("false")
		end)

		it("should serialize enum items", function()
			local result = Serializer.tableValue(Enum.SortOrder.LayoutOrder)

			expect(result).to.equal("Enum.SortOrder.LayoutOrder")
		end)

		it("should serialize Color3", function()
			local result = Serializer.tableValue(Color3.new(0.1, 0.2, 0.3))

			expect(result).to.equal("Color3.new(0.1, 0.2, 0.3)")
		end)

		it("should serialize Rect", function()
			local result = Serializer.tableValue(Rect.new(0.1, 0.2, 0.3, 0.4))

			expect(result).to.equal("Rect.new(0.1, 0.2, 0.3, 0.4)")
		end)

		it("should serialize UDim", function()
			local result = Serializer.tableValue(UDim.new(1.2, 0))

			expect(result).to.equal("UDim.new(1.2, 0)")
		end)

		it("should serialize UDim2", function()
			local result = Serializer.tableValue(UDim2.new(1.5, 5, 2, 3))

			expect(result).to.equal("UDim2.new(1.5, 5, 2, 3)")
		end)

		it("should serialize Vector2", function()
			local result = Serializer.tableValue(Vector2.new(1.5, 0.3))

			expect(result).to.equal("Vector2.new(1.5, 0.3)")
		end)

		it("should serialize markers symbol", function()
			for name, marker in pairs(Markers) do
				local result = Serializer.tableValue(marker)

				expect(result).to.equal(("Markers.%s"):format(name))
			end
		end)

		it("should serialize Roact.Event events", function()
			local result = Serializer.tableValue(Event.Activated)

			expect(result).to.equal("Roact.Event.Activated")
		end)

		it("should serialize Roact.Change events", function()
			local result = Serializer.tableValue(Change.AbsoluteSize)

			expect(result).to.equal("Roact.Change.AbsoluteSize")
		end)
	end)

	describe("table", function()
		it("should serialize an empty nested table", function()
			local output = IndentedOutput.new()
			Serializer.table("sub", {}, output)

			expect(output:join()).to.equal("sub = {},")
		end)

		it("should serialize an nested table", function()
			local output = IndentedOutput.new()
			Serializer.table("sub", {
				foo = 1,
			}, output)

			expect(output:join()).to.equal("sub = {\n  foo = 1,\n},")
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
				[Event.Activated] = Markers.AnonymousFunction,
			}, output)

			expect(output:join()).to.equal(
				   "props = {\n"
				.. "  [Roact.Event.Activated] = Markers.AnonymousFunction,\n"
				.. "},"
			)
		end)

		it("should sort Roact.Event", function()
			local output = IndentedOutput.new()
			Serializer.props({
				[Event.Activated] = Markers.AnonymousFunction,
				[Event.MouseEnter] = Markers.AnonymousFunction,
			}, output)

			expect(output:join()).to.equal(
				   "props = {\n"
				.. "  [Roact.Event.Activated] = Markers.AnonymousFunction,\n"
				.. "  [Roact.Event.MouseEnter] = Markers.AnonymousFunction,\n"
				.. "},"
			)
		end)

		it("should serialize Roact.Change", function()
			local output = IndentedOutput.new()
			Serializer.props({
				[Change.Position] = Markers.AnonymousFunction,
			}, output)

			expect(output:join()).to.equal(
				   "props = {\n"
				.. "  [Roact.Change.Position] = Markers.AnonymousFunction,\n"
				.. "},"
			)
		end)

		it("should sort props, Roact.Event, Roact.Change and Ref", function()
			local output = IndentedOutput.new()
			Serializer.props({
				foo = 1,
				[Event.Activated] = Markers.AnonymousFunction,
				[Change.Position] = Markers.AnonymousFunction,
				[Ref] = Markers.EmptyRef,
			}, output)

			expect(output:join()).to.equal(
				   "props = {\n"
				.. "  foo = 1,\n"
				.. "  [Roact.Event.Activated] = Markers.AnonymousFunction,\n"
				.. "  [Roact.Change.Position] = Markers.AnonymousFunction,\n"
				.. "  [Roact.Ref] = Markers.EmptyRef,\n"
				.. "},"
			)
		end)

		it("should sort props within themselves", function()
			local output = IndentedOutput.new()
			Serializer.props({
				foo = 1,
				bar = 2,
			}, output)

			expect(output:join()).to.equal(
				   "props = {\n"
				.. "  bar = 2,\n"
				.. "  foo = 1,\n"
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