local math = math
local min = math.min
local abs = math.abs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local Widget = require("GUI.Widget")

local BoxSelect = {}
function BoxSelect:new(parameters)
    local parameters = parameters or {}
    local self = Widget:new(parameters)

    self.x1 = 0
    self.x2 = 0
    self.y1 = 0
    self.y2 = 0
    self.insideColor = { 0, 0, 0, 0.3, 0 }
    self.edgeColor = { 1, 1, 1, 0.6, 0 }
    self.isActive = false
    function self:startSelection(startingX, startingY)
        self.x1 = startingX
        self.x2 = startingX
        self.y1 = startingY
        self.y2 = startingY

        self.x = startingX
        self.y = startingY
        self.width = 0
        self.height = 0

        self.shouldRedraw = true
    end
    function self:editSelection(editX, editY)
        self.isActive = true
        self.x2 = editX
        self.y2 = editY

        self.x = min(self.x1, self.x2)
        self.y = min(self.y1, self.y2)
        self.width = abs(self.x1 - self.x2)
        self.height = abs(self.y1 - self.y2)

        self.shouldRedraw = true
    end
    function self:makeSelection(parameters)
        local thingsToSelect = parameters.thingsToSelect
        local isInsideFunction = parameters.isInsideFunction
        local setSelectedFunction = parameters.setSelectedFunction
        local getSelectedFunction = parameters.getSelectedFunction
        local shouldAdd = parameters.shouldAdd
        local shouldInvert = parameters.shouldInvert

        for i = 1, #thingsToSelect do
            local thing = thingsToSelect[i]

            if isInsideFunction(self, thing) then
                if shouldInvert then
                    setSelectedFunction(thing, not getSelectedFunction(thing))
                else
                    setSelectedFunction(thing, true)
                end
            else
                if not shouldAdd and not shouldInvert then
                    setSelectedFunction(thing, false)
                end
            end
        end

        self.isActive = false
        self.shouldRedraw = true
    end

    function self:draw()
        local width = self.width
        local height = self.height

        if self.isActive then
            self:setColor(self.edgeColor)
            self:drawRectangle(0, 0, width, height, false)

            self:setColor(self.insideColor)
            self:drawRectangle(1, 1, width - 2, height - 2, true)
        end
    end

    for k, v in pairs(parameters) do self[k] = v end
    return self
end

return BoxSelect