package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFXChild = require("GFX.GFXChild")

local BoxSelect = setmetatable({}, { __index = GFXChild })

function BoxSelect:new(init)
    local init = init or {}
    if init.gfxAPI == nil then return nil end

    local base = GFXChild:new(init)
    local self = setmetatable(base, { __index = self })

    self._insideColor = init.insideColor or {1.0, 1.0, 1.0, 0.05}
    self._edgeColor   = init.edgeColor   or {1.0, 1.0, 1.0, 0.3}
    self._isActive = false
    self._x1 = 0
    self._x2 = 0
    self._y1 = 0
    self._y2 = 0

    return self
end

function BoxSelect:activate(startingX, startingY)
    self._isActive = true
    self._x1 = startingX
    self._x2 = startingX
    self._y1 = startingY
    self._y2 = startingY

    self:setX(startingX)
    self:setY(startingY)
    self:setWidth(0)
    self:setHeight(0)
end

function BoxSelect:edit(editX, editY)
    self._x2 = editX
    self._y2 = editY

    local boxX = math.min(self._x1, self._x2)
    local boxY = math.min(self._y1, self._y2)
    local boxWidth = math.abs(self._x1 - self._x2)
    local boxHeight = math.abs(self._y1 - self._y2)

    self:setX(boxX)
    self:setY(boxY)
    self:setWidth(boxWidth)
    self:setHeight(boxHeight)
end

function BoxSelect:deactivate()
    self._isActive = false
end

function BoxSelect:draw()
    local isActive = self._isActive

    if isActive then
        local GFX = self:getGFXAPI()
        local insideColor = self._insideColor
        local edgeColor = self._edgeColor
        local width = self:getWidth()
        local height = self:getHeight()

        GFX:setColor(edgeColor)
        self:rect(0, 0, width, height, false)

        GFX:setColor(insideColor)
        self:rect(1, 1, width - 2, height - 2, true)
    end
end

return BoxSelect