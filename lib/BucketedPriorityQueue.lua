--[[
	This is an implementation of a priority queue using a priority-bucketed
	approach as opposed to a heap, which is more traditional.

	A priority queue backed by a binary heap has O(log n) insertion and
	deletion, which isn't the scaling guarantees that we want for Roact's task
	queue, which can insert tasks at any priority and needs to quickly pop
	elements as the queue is processed.

	BucktedPriorityQueue aims to have O(1) insertion and deletion by relying on
	priority of the inserted objects being countable and nearly continuous.
	Additionally, since Lua already introduces indirection for every table-based
	object, the extra layer of indirection introduced shouldn't impact memory
	locality severely.

	BucketedPriorityQueue is not stable on insertion order, so entries with the
	same priority may be pulled out in any order.
]]

local BucketedPriorityQueue = {}
BucketedPriorityQueue.prototype = {}
BucketedPriorityQueue.__index = BucketedPriorityQueue.prototype

function BucketedPriorityQueue.new()
	local self = {
		_buckets = {{}},
		_lowestOccupiedBucket = 1,
		_empty = true,

		count = 0,
	}

	setmetatable(self, BucketedPriorityQueue)

	return self
end

function BucketedPriorityQueue.prototype:insert(priority, item)
	if priority > #self._buckets then
		for i = #self._buckets + 1, priority do
			self._buckets[i] = {}
		end
	end

	local bucket = self._buckets[priority]

	bucket[#bucket + 1] = item

	self._lowestOccupiedBucket = math.min(self._lowestOccupiedBucket, priority)
	self.count = self.count + 1
end

function BucketedPriorityQueue.prototype:pop()
	local bucketCount = #self._buckets

	for i = self._lowestOccupiedBucket, bucketCount do
		local bucket = self._buckets[i]
		local size = #bucket

		if size > 0 then
			local item = bucket[size]
			bucket[size] = nil

			self._lowestOccupiedBucket = i
			self.count = self.count - 1

			return item
		end
	end

	self._lowestOccupiedBucket = bucketCount

	return nil
end

return BucketedPriorityQueue