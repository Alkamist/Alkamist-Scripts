local math = math
local min = math.min
local abs = math.abs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")

local BoxSelect = {}
function BoxSelect:new(parameters)
    local parameters = parameters or {}
    local self = Widget:new(parameters)

    local _x1 = 0
    local _x2 = 0
    local _y1 = 0
    local _y2 = 0
    local _insideColor = parameters.insideColor or { 0, 0, 0, 0.4, 0 }
    local _edgeColor = parameters.edgeColor or { 1, 1, 1, 0.7, 0 }
    local _isActive = false

    function self:startSelection(startingX, startingY)
        _x1 = startingX
        _x2 = startingX
        _y1 = startingY
        _y2 = startingY
        self:setX(startingX)
        self:setY(startingY)
        self:setWidth(0)
        self:setHeight(0)
        self:queueRedraw()
    end
    function self:editSelection(editX, editY)
        _isActive = true
        _x2 = editX
        _y2 = editY

        self:setX(min(_x1, _x2))
        self:setY(min(_y1, _y2))
        self:setWidth(abs(_x1 - _x2))
        self:setHeight(abs(_y1 - _y2))
        self:queueRedraw()
    end
    function self:makeSelection(parameters)
        local parameters = parameters or {}
        local thingsToSelect = parameters.thingsToSelect
        local isInsideFunction = parameters.isInsideFunction
        local setSelectedFunction = parameters.setSelectedFunction
        local getSelectedFunction = parameters.getSelectedFunction
        local shouldAdd = parameters.shouldAdd
        local shouldInvert = parameters.shouldInvert

        if thingsToSelect then
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
        end

        _isActive = false
        self:queueClear()
    end

    function self:draw()
        local width = self:getWidth()
        local height = self:getHeight()

        if _isActive then
            self:setColor(_edgeColor)
            self:drawRectangle(0, 0, width, height, false)

            self:setColor(_insideColor)
            self:drawRectangle(1, 1, width - 2, height - 2, true)
        end
    end

    return self
end

return BoxSelect