return function()
	local BucketedPriorityQueue = require(script.Parent.BucketedPriorityQueue)

	it("should create successfully", function()
		local queue = BucketedPriorityQueue.new()

		expect(queue).to.be.ok()
		expect(queue.count).to.equal(0)
	end)

	it("should push into different priorities and pop from them", function()
		local queue = BucketedPriorityQueue.new()

		queue:insert(1, "Hello")
		queue:insert(2, "World")
		queue:insert(2, "Mom")
		queue:insert(3, "Nice")

		expect(queue.count).to.equal(4)

		local value1 = queue:pop()

		expect(value1).to.equal("Hello")
		expect(queue.count).to.equal(3)

		local value2a = queue:pop()
		local value2b = queue:pop()

		-- The order which these will be popped is not defined!
		if value2a == "World" then
			expect(value2b).to.equal("Mom")
		else
			expect(value2a).to.equal("Mom")
			expect(value2b).to.equal("World")
		end

		expect(queue.count).to.equal(1)

		local value3 = queue:pop()

		expect(value3).to.equal("Nice")
		expect(queue.count).to.equal(0)

		local none = queue:pop()

		expect(none).to.equal(nil)
		expect(queue.count).to.equal(0)
	end)
end