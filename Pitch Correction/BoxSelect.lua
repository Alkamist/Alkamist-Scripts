local math = math
local abs = math.abs
local min = math.min

local BoxSelect = {}

function BoxSelect.new(selectionControl, additiveStateFn, inversionStateFn)
    local self = {}

    self.x1 = 0
    self.x2 = 0
    self.y1 = 0
    self.y2 = 0
    self.isActive = false
    self.thingsToSelect = {}
    self.selectionControl = selectionButton
    self.additiveStateFn = additiveStateFn
    self.inversionStateFn = inversionStateFn

    local function _startSelection(self, startingX, startingY)
        self.x1 = startingX
        self.x2 = startingX
        self.y1 = startingY
        self.y2 = startingY
        self.x = startingX
        self.y = startingY
        self.width = 0
        self.height = 0
    end
    local function _editSelection(editX, editY)
        self.isActive = true
        self.x2 = editX
        self.y2 = editY
        self.x = min(self.x1, self.x2)
        self.y = min(self.y1, self.y2)
        self.width = abs(self.x1 - self.x2)
        self.height = abs(self.y1 - self.y2)
    end
    local function _makeSelection(self)
        local thingsToSelect = self.thingsToSelect
        local thingIsInside = self.thingIsInside
        local setThingSelected = self.setThingSelected
        local thingIsSelected = self.thingIsSelected
        local shouldAdd = additiveStateFn()
        local shouldInvert = inversionStateFn()

        if thingsToSelect then
            for i = 1, #thingsToSelect do
                local thing = thingsToSelect[i]

                if thingIsInside(self, thing) then
                    if shouldInvert then
                        setThingSelected(self, thing, not thingIsSelected(self, thing))
                    else
                        setThingSelected(self, thing, true)
                    end
                else
                    if not shouldAdd and not shouldInvert then
                        setThingSelected(self, thing, false)
                    end
                end
            end
        end
        self.isActive = false
    end

    function BoxSelect:thingIsInside(thing)
        return self:pointIsInside(thing)
    end
    function BoxSelect:setThingSelected(thing, shouldSelect)
        thing.isSelected = shouldSelect
    end
    function BoxSelect:thingIsSelected(thing)
        return thing.isSelected
    end
    function BoxSelect:update()
        local selectionControl = self.selectionControl
        if selectionControl:justPressed() then _startSelection(self, selectionControl.x, selectionControl.y) end
        if selectionControl.isPressed then _editSelection(self, selectionControl.x, selectionControl.y) end
        if selectionControl:justReleased() then _makeSelection(self) end
    end

    return self
end

return BoxSelect