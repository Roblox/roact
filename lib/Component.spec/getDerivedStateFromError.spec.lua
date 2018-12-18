return function()
    local createElement = require(script.Parent.Parent.createElement)
    local createReconciler = require(script.Parent.Parent.createReconciler)
    local NoopRenderer = require(script.Parent.Parent.NoopRenderer)

    local Component = require(script.Parent.Parent.Component)

    local noopReconciler = createReconciler(NoopRenderer)

    it("should not be called if the component doesn't throw", function()
        local callCount = 0

        local Boundary = Component:extend("Boundary")

        function Boundary.getDerivedStateFromError(message)
            callCount = callCount + 1
        end

        function Boundary:render()
            return nil
        end

        local element = createElement(Boundary)
        local hostParent = nil
        local key = "Test"

        noopReconciler.mountVirtualNode(element, hostParent, key)
        expect(callCount).to.equal(0)
    end)

    it("should be called with the error message", function()
        local callCount = 0

        local function Bug()
            error("test error")
        end

        local Boundary = Component:extend("Boundary")

        function Boundary.getDerivedStateFromError(message)
            callCount = callCount + 1
            -- the error message will not be the same as what's thrown because a
            -- line/source object as well as stack trace will be attached to it
            expect(message).to.be.ok()

            return {}
        end

        function Boundary:render()
            return createElement(Bug)
        end

        local element = createElement(Boundary)
        local hostParent = nil
        local key = "Test"

        -- This will throw, because we don't stop rendering the throwing
        -- component in response to the error. We test this more
        -- rigorously elsewhere; this is just to keep the test from failing.
        expect(function()
            noopReconciler.mountVirtualNode(element, hostParent, key)
        end).to.throw()
        expect(callCount).to.equal(1)
    end)

    it("should throw an error if the fallback render throws", function()
        local renderCount = 0

        local function Bug()
            error("test error")
        end

        local Boundary = Component:extend("Boundary")

        function Boundary.getDerivedStateFromError(message)
            return {}
        end

        function Boundary:render()
            renderCount = renderCount + 1
            return createElement(Bug)
        end

        local element = createElement(Boundary)
        local hostParent = nil
        local key = "Test"

        expect(function()
            noopReconciler.mountVirtualNode(element, hostParent, key)
        end).to.throw()
        expect(renderCount).to.equal(2)
    end)

    it("should return a state delta for the component", function()
        local renderCount = 0
        local getStateCallback = nil

        local function Bug()
            error("test error")
        end

        local Boundary = Component:extend("Boundary")

        function Boundary.getDerivedStateFromError(message)
            return {
                errored = true
            }
        end

        function Boundary:init()
            getStateCallback = function()
                return self.state
            end
        end

        function Boundary:render()
            renderCount = renderCount + 1
            if renderCount > 1 then
                expect(self.state.errored).to.equal(true)
            end

            if self.state.errored then
                return nil
            else
                return createElement(Bug)
            end
        end

        local element = createElement(Boundary)
        local hostParent = nil
        local key = "Test"

        noopReconciler.mountVirtualNode(element, hostParent, key)
        expect(renderCount).to.equal(2)
        expect(getStateCallback().errored).to.equal(true)
    end)

    it("should not interrupt the lifecycle methods", function()
        local didMountCount = 0
        local didUpdateCount = 0
        local setStateCallback = nil

        local function Bug()
            error("test error")
        end

        local Boundary = Component:extend("Boundary")

        function Boundary.getDerivedStateFromError(message)
            return {
                errored = true
            }
        end

        function Boundary:init()
            setStateCallback = function(delta)
                self:setState(delta)
            end
        end

        function Boundary:render()
            if self.state.errored then
                return nil
            else
                return createElement(Bug)
            end
        end

        function Boundary:didMount()
            didMountCount = didMountCount + 1
        end

        function Boundary:didUpdate()
            didUpdateCount = didUpdateCount + 1
        end

        local element = createElement(Boundary)
        local hostParent = nil
        local key = "Test"

        noopReconciler.mountVirtualNode(element, hostParent, key)
        expect(didMountCount).to.equal(1)
        expect(didUpdateCount).to.equal(0)
        setStateCallback({
            errored = false
        })

        expect(didUpdateCount).to.equal(1)
    end)
end