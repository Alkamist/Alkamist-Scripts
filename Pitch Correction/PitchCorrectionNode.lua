package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFXChild = require("GFX.GFXChild")

local PitchCorrectionNode = setmetatable({}, { __index = GFXChild })

function PitchCorrectionNode:new(init)
    local init = init or {}
    --if init.GFX == nil then return nil end

    local base = GFXChild:new(init)
    local self = setmetatable(base, { __index = self })

    self.activeColor =   init.activeColor   or {0.7, 0.7, 1.0, 1.0}
    self.inactiveColor = init.inactiveColor or {1.0, 0.3, 0.3, 1.0}

    self.nextNode =      init.nextNode
    self.previousNode =  init.previousNode
    self.isActive =      init.isActive or false
    self.isSelected =    init.isSelected or false

    return self
end

function PitchCorrectionNode:getNextNode()         return self.nextNode end
function PitchCorrectionNode:getPreviousNode()     return self.previousNode end

function PitchCorrectionNode:setNextNode(node)     self.nextNode = node end
function PitchCorrectionNode:setPreviousNode(node) self.previousNode = node end

function PitchCorrectionNode:draw()
    local GFX = self:getGFX()
    local nextNode = self:getNextNode()
    local isActive = self.isActive
    local isSelected = self.isSelected
    local activeColor = self.activeColor
    local inactiveColor = self.inactiveColor
    local circlePixelRadius = 3

    if isActive then
        GFX:setColor(activeColor)
    else
        GFX:setColor(inactiveColor)
    end

    self:circle(0, 0, circlePixelRadius, true, true)

    if isActive and nextNode then
        local nextNodeX = nextNode:getX() - self:getX()
        local nextNodeY = nextNode:getY() - self:getY()

        self:line(0, 0, nextNodeX, nextNodeY, true)
    end
end

return PitchCorrectionNode