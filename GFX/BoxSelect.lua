local BoxSelect = {}

function BoxSelect:new(init)
    local init = init or {}
    local self = setmetatable({}, { __index = self })

    self.x = 0
    self.y = 0
    self.w = 0
    self.h = 0

    self.x1 = 0
    self.x2 = 0
    self.y1 = 0
    self.y2 = 0

    self.parent =      init.parent
    self.insideColor = init.insideColor or {1.0, 1.0, 1.0, -0.08, 1}
    self.edgeColor   = init.edgeColor   or {1.0, 1.0, 1.0, 0.4, 1}

    self.isActive = false

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
            if not shouldAdd then
                setSelectedFn(thing, false)
            end
        end
    end
    self.isActive = false
end

function BoxSelect:draw()
    if self.parent and self.isActive then
        self.parent:setColor(self.edgeColor)
        self.parent:drawRectangle(self.x, self.y, self.w, self.h, false)

        self.parent:setColor(self.insideColor)
        self.parent:drawRectangle(self.x + 1, self.y + 1, self.w - 2, self.h - 2, true)
    end
end

return BoxSelect