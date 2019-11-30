local math = math
local abs = math.abs
local min = math.min

local BoxSelect = {}

function BoxSelect.new(bounds, selectionControl, additiveStateFn, inversionStateFn)
    local self = {}

    self.bounds = bounds
    self.isActive = false
    self.thingsToSelect = {}
    self.selectionControl = selectionButton
    self.additiveStateFn = additiveStateFn
    self.inversionStateFn = inversionStateFn

    local function _startSelection(self, startingX, startingY)
        local bounds = self.bounds
        bounds.x = startingX
        bounds.y = startingY
        bounds.width = 0
        bounds.height = 0
    end
    local function _editSelection(editX, editY)
        local bounds = self.bounds
        self.isActive = true

        local x1 = self.x
        local y1 = self.y
        local x2 = editX
        local y2 = editY

        bounds.x = min(x1, x2)
        bounds.y = min(y1, y2)
        bounds.width = abs(x1 - x2)
        bounds.height = abs(y1 - y2)
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