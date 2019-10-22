local BoxSelect = {}

function BoxSelect:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.GFX = init.GFX

    self.x = 0
    self.y = 0
    self.w = 0
    self.h = 0
    self.x1 = 0
    self.x2 = 0
    self.y1 = 0
    self.y2 = 0
    self.isActive = false

    self.insideColor = init.insideColor or {0.0, 0.0, 0.0, 0.15}
    self.edgeColor   = init.edgeColor   or {1.0, 1.0, 1.0, 0.5}

    self.thingsToSelect =              init.thingsToSelect or {}

    return self
end

function BoxSelect:pointIsInside(x, y)
    return x >= self.x and x <= self.x + self.w
       and y >= self.y and y <= self.y + self.h
end

function BoxSelect:startSelection(startingX, startingY)
    self.isActive = true

    self.x1 = startingX
    self.x2 = startingX
    self.y1 = startingY
    self.y2 = startingY
end

function BoxSelect:editSelection(editX, editY)
    self.x2 = editX
    self.y2 = editY

    self.x = math.min(self.x1, self.x2)
    self.y = math.min(self.y1, self.y2)
    self.w = math.abs(self.x1 - self.x2)
    self.h = math.abs(self.y1 - self.y2)
end

function BoxSelect:makeSelection(shouldAdd, shouldInvert)
    local selectedIndexes = {}
    local numberOfThings = #self.thingsToSelect
    for i = 1, numberOfThings do
        local thing = self.thingsToSelect[i]

        if self:pointIsInside(thing.x, thing.y) then
            if shouldInvert then
                self:setSelected(thing, i, selectedIndexes, not thing.isSelected)
            else
                self:setSelected(thing, i, selectedIndexes, true)
            end
        else
            if not shouldAdd then
                self:setSelected(thing, i, selectedIndexes, false)
            end
        end
    end
    self.isActive = false
    return selectedIndexes
end

function BoxSelect:setSelected(thing, thingsIndex, selectedIndexes, shouldSelect)
    thing.isSelected = shouldSelect
    selectedIndexes[#selectedIndexes + 1] = thingsIndex
end

function BoxSelect:draw()
    if self.isActive then
        self.GFX:setColor(self.edgeColor)
        self.GFX:drawRectangle(self.x, self.y, self.w, self.h, false)

        self.GFX:setColor(self.insideColor)
        self.GFX:drawRectangle(self.x + 1, self.y + 1, self.w - 2, self.h - 2, true)
    end
end

return BoxSelect