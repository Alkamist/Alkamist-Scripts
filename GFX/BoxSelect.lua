package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require("GFX.AlkamistGFX")
local Prototype = require("Prototype")

local BoxSelect = {
    x1 = 0,
    x2 = 0,
    y1 = 0,
    y2 = 0,
    insideColor = {1.0, 1.0, 1.0, -0.04, 1},
    edgeColor = {1.0, 1.0, 1.0, 0.2, 1},
    isActive = false
}

function BoxSelect:new(parameters)
    local element = GFX.createElement(parameters)
    return Prototype.addPrototypes(element, { BoxSelect })
end

function BoxSelect:startSelection(startingX, startingY)
    self.x1 = startingX
    self.x2 = startingX
    self.y1 = startingY
    self.y2 = startingY

    self:setX(startingX)
    self:setY(startingY)
    self:setWidth(0)
    self:setHeight(0)

    self:queueRedraw()
end
function BoxSelect:editSelection(editX, editY)
    self.isActive = true

    self.x2 = editX
    self.y2 = editY

    self:setX(math.min(self.x1, self.x2))
    self:setY(math.min(self.y1, self.y2))
    self:setWidth(math.abs(self.x1 - self.x2))
    self:setHeight(math.abs(self.y1 - self.y2))

    self:queueRedraw()
end
function BoxSelect:makeSelection(parameters)
    local listOfThings = parameters.listOfThings
    local isInsideFn = parameters.isInsideFn
    local setSelectedFn = parameters.setSelectedFn
    local getSelectedFn = parameters.getSelectedFn
    local shouldAdd = parameters.shouldAdd
    local shouldInvert = parameters.shouldInvert

    local numberOfThings = #listOfThings
    for i = 1, numberOfThings do
        local thing = listOfThings[i]

        if isInsideFn(self, thing) then
            if shouldInvert then
                setSelectedFn(thing, not getSelectedFn(thing))
            else
                setSelectedFn(thing, true)
            end
        else
            if not shouldAdd and not shouldInvert then
                setSelectedFn(thing, false)
            end
        end
    end
    self.isActive = false
    self:queueClear()
end

function BoxSelect:draw()
    local width = self:getWidth()
    local height = self:getHeight()

    if self.isActive then
        self:setColor(self.edgeColor)
        self:drawRectangle(0, 0, width, height, false)

        self:setColor(self.insideColor)
        self:drawRectangle(1, 1, width - 2, height - 2, true)
    end
end

return BoxSelect