package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFXChild = require("GFX.GFXChild")

local BoxSelect = setmetatable({}, { __index = GFXChild })

function BoxSelect:new(init)
    local init = init or {}
    --if init.GFX == nil then return nil end

    local base = GFXChild:new(init)
    local self = setmetatable(base, { __index = self })

    self.insideColor = init.insideColor or {1.0, 1.0, 1.0, 0.05}
    self.edgeColor   = init.edgeColor   or {1.0, 1.0, 1.0, 0.3}
    self.isActive = false
    self.x1 = 0
    self.x2 = 0
    self.y1 = 0
    self.y2 = 0

    return self
end

function BoxSelect:activate(startingX, startingY)
    self.isActive = true
    self.x1 = startingX
    self.x2 = startingX
    self.y1 = startingY
    self.y2 = startingY

    self:setX(startingX)
    self:setY(startingY)
    self:setWidth(0)
    self:setHeight(0)
end

function BoxSelect:edit(editX, editY)
    self.x2 = editX
    self.y2 = editY

    local boxX = math.min(self.x1, self.x2)
    local boxY = math.min(self.y1, self.y2)
    local boxWidth = math.abs(self.x1 - self.x2)
    local boxHeight = math.abs(self.y1 - self.y2)

    self:setX(boxX)
    self:setY(boxY)
    self:setWidth(boxWidth)
    self:setHeight(boxHeight)
end

function BoxSelect:deactivate()
    self.isActive = false
end

function BoxSelect:draw()
    local isActive = self.isActive

    if isActive then
        local GFX = self:getGFX()
        local insideColor = self.insideColor
        local edgeColor = self.edgeColor
        local width = self:getWidth()
        local height = self:getHeight()

        GFX:setColor(edgeColor)
        self:rect(0, 0, width, height, false)

        GFX:setColor(insideColor)
        self:rect(1, 1, width - 2, height - 2, true)
    end
end

return BoxSelect