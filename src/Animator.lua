--[[
    Written by Bradsharp.
]]
local Symbol = require(script.Parent.Symbol)
local Type = require(script.Parent.Type)

local AnimatorImpl = Symbol.named("AnimatorImpl")
local AnimatorInternalApi = {}
local animationPrototype = {}

function animationPrototype:getValue()
    return self[AnimatorImpl].value
end

function animationPrototype:getTweenInfo()
    return self[AnimatorImpl].tweenInfo
end

local AnimationPublicMeta = {
    __index = animationPrototype,
    __tostring = function(self)
        return string.format("RoactAnimation(%s)", tostring(self:getValue()))
    end
}

function AnimatorInternalApi.create(...)
    local tweenInfo = TweenInfo.new(...)

    return function(newValue)
        return setmetatable(
            {
                [Type] = Type.Animation,
                [AnimatorImpl] = {
                    tweenInfo = tweenInfo,
                    value = newValue
                }
            },
            AnimationPublicMeta
        )
    end
end

return AnimatorInternalApi
