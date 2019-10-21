package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFXChild = require("GFX.GFXChild")

local BoxSelect = setmetatable({}, { __index = GFXChild })

function BoxSelect:new(init)
    local init = init or {}

    local base = GFXChild:new(init)
    local self = setmetatable(base, { __index = self })

    self.insideColor = init.insideColor or {0.0, 0.0, 0.0, 0.15}
    self.edgeColor   = init.edgeColor   or {1.0, 1.0, 1.0, 0.5}
    self.isActive = false
    self.x1 = 0
    self.x2 = 0
    self.y1 = 0
    self.y2 = 0
    self.thingsToSelect = init.thingsToSelect or {}
    self.inversionKey =   init.inversionKey
    self.additiveKey =    init.additiveKey

    return self
end

function BoxSelect:activate(startingX, startingY)
    self.isActive = true
    self.x1 = startingX
    self.x2 = startingX
    self.y1 = startingY
    self.y2 = startingY

    self.x:update(startingX)
    self.y:update(startingY)
    self.width:update(0)
    self.height:update(0)
end

function BoxSelect:edit(editX, editY)
    self.x2 = editX
    self.y2 = editY

    local boxX =      math.min(self.x1, self.x2)
    local boxY =      math.min(self.y1, self.y2)
    local boxWidth =  math.abs(self.x1 - self.x2)
    local boxHeight = math.abs(self.y1 - self.y2)

    self.x:update(boxX)
    self.y:update(boxY)
    self.width:update(boxWidth)
    self.height:update(boxHeight)
end

function BoxSelect:deactivate()
    self.isActive = false

    for _, thing in ipairs(self.thingsToSelect) do
        if self:pointIsInside(thing.x.current, thing.y.current) then
            thing.isSelected:update(true)
        end
    end
end

function BoxSelect:draw()
    if self.isActive then
        self:setColor(self.edgeColor)
        self:drawRectangle(0, 0, self.width.current, self.height.current, false)

        self:setColor(self.insideColor)
        self:drawRectangle(1, 1, self.width.current - 2, self.height.current - 2, true)
    end
end

return BoxSelect