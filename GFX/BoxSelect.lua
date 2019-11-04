local BoxSelect = {
    x = 0,
    y = 0,
    w = 0,
    h = 0,
    x1 = 0,
    x2 = 0,
    y1 = 0,
    y2 = 0,
    insideColor = {1.0, 1.0, 1.0, -0.04, 1},
    edgeColor = {1.0, 1.0, 1.0, 0.2, 1},
    isActive = false
}

function BoxSelect:new(input)
    return Class:new({ BoxSelect }, input)
end

function BoxSelect:startSelection(startingX, startingY)
    self.x1 = startingX
    self.x2 = startingX
    self.y1 = startingY
    self.y2 = startingY
end
function BoxSelect:editSelection(editX, editY)
    self.isActive = true

    self.x2 = editX
    self.y2 = editY

    self.x = math.min(self.x1, self.x2)
    self.y = math.min(self.y1, self.y2)
    self.w = math.abs(self.x1 - self.x2)
    self.h = math.abs(self.y1 - self.y2)
end
function BoxSelect:makeSelection(listOfThings, setSelectedFn, getSelectedFn, shouldAdd, shouldInvert)
    local numberOfThings = #listOfThings
    for i = 1, numberOfThings do
        local thing = listOfThings[i]

        if self:pointIsInside(thing.x, thing.y) then
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
end

function BoxSelect:draw()
    if self.isActive then
        self:setColor(self.edgeColor)
        self:drawRectangle(0, 0, self.w, self.h, false)

        self:setColor(self.insideColor)
        self:drawRectangle(1, 1, self.w - 2, self.h - 2, true)
    end
end

return BoxSelect