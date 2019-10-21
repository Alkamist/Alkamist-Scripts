package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Switch = require("Logic.Switch")
local GFXChild = require("GFX.GFXChild")

local PitchCorrectionNode = setmetatable({}, { __index = GFXChild })

function PitchCorrectionNode:new(init)
    local init = init or {}

    local base = GFXChild:new(init)
    local self = setmetatable(base, { __index = self })

    self.activeColor =           init.activeColor   or {0.7, 0.7, 1.0, 1.0}
    self.inactiveColor =         init.inactiveColor or {1.0, 0.3, 0.3, 1.0}
    self.activeUnselectedColor = { self.activeColor[1] * 0.5,
                                   self.activeColor[2] * 0.5,
                                   self.activeColor[3] * 0.5,
                                   self.activeColor[4] }
    self.inactiveUnselectedColor = { self.inactiveColor[1] * 0.5,
                                     self.inactiveColor[2] * 0.5,
                                     self.inactiveColor[3] * 0.5,
                                     self.inactiveColor[4] }

    self.nextNode =      init.nextNode
    self.previousNode =  init.previousNode
    self.isActive =      Switch:new(init.isActive or false)
    self.isSelected =    Switch:new(init.isSelected or false)

    return self
end

function PitchCorrectionNode:draw()
    local circlePixelRadius = 3

    if self.isActive.current then
        if self.isSelected.current then
            self:setColor(self.activeColor)
        else
            self:setColor(self.activeUnselectedColor)
        end
    else
        if self.isSelected.current then
            self:setColor(self.inactiveColor)
        else
            self:setColor(self.inactiveUnselectedColor)
        end
    end

    self:drawCircle(0, 0, circlePixelRadius, true, true)

    if self.isActive.current and self.nextNode then
        local nextNodeX = self.nextNode.x.current - self.x.current
        local nextNodeY = self.nextNode.y.current - self.y.current

        self:drawLine(0, 0, nextNodeX, nextNodeY, true)
    end
end

return PitchCorrectionNode