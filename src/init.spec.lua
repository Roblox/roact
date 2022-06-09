return function()
	local Roact = require(script.Parent)

	it("should load with all public APIs", function()
		local publicApi = {
			createElement = "function",
			createFragment = "function",
			createRef = "function",
			forwardRef = "function",
			createBinding = "function",
			joinBindings = "function",
			mount = "function",
			unmount = "function",
			update = "function",
			oneChild = "function",
			setGlobalConfig = "function",
			createContext = "function",

			-- These functions are deprecated and throw warnings!
			reify = "function",
			teardown = "function",
			reconcile = "function",

			Component = true,
			PureComponent = true,
			Portal = true,
			Children = true,
			Event = true,
			Change = true,
			Ref = true,
			None = true,
			UNSTABLE = true,
		}

		expect(Roact).to.be.ok()

		for key, valueType in pairs(publicApi) do
			local success
			if typeof(valueType) == "string" then
				success = typeof(Roact[key]) == valueType
			else
				success = Roact[key] ~= nil
			end

			if not success then
				local existence = typeof(valueType) == "boolean" and "present" or "of type " .. tostring(valueType)
				local message = ("Expected public API member %q to be %s, but instead it was of type %s"):format(
					tostring(key),
					existence,
					typeof(Roact[key])
				)

				error(message)
			end
		end

		for key in pairs(Roact) do
			if publicApi[key] == nil then
				local message = ("Found unknown public API key %q!"):format(tostring(key))

				error(message)
			end
		end
	end)
end
