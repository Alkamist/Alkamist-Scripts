local math = math
local min = math.min
local abs = math.abs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")
local Widget = require("GUI.Widget")

return Prototype:new{
    calledWhenCreated = function(self) end,

    prototypes = {
        { "widget", Widget }
    },
    x1 = 0,
    x2 = 0,
    y1 = 0,
    y2 = 0,
    insideColor = { 0, 0, 0, 0.3, 0 },
    edgeColor = { 1, 1, 1, 0.6, 0 },
    isActive = false,
    startSelection = function(self, startingX, startingY)
        self.x1 = startingX
        self.x2 = startingX
        self.y1 = startingY
        self.y2 = startingY

        self.x = startingX
        self.y = startingY
        self.width = 0
        self.height = 0

        self.shouldRedraw = true
    end,
    editSelection = function(self, editX, editY)
        self.isActive = true
        self.x2 = editX
        self.y2 = editY

        self.x = min(self.x1, self.x2)
        self.y = min(self.y1, self.y2)
        self.width = abs(self.x1 - self.x2)
        self.height = abs(self.y1 - self.y2)

        self.shouldRedraw = true
    end,
    makeSelection = function(self, parameters)
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
    end,

    draw = function(self)
        local width = self.width
        local height = self.height

        if self.isActive then
            self:setColor(self.edgeColor)
            self:drawRectangle(0, 0, width, height, false)

            self:setColor(self.insideColor)
            self:drawRectangle(1, 1, width - 2, height - 2, true)
        end
    end,
}