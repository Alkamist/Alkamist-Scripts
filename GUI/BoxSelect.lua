package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Widget = require("GUI.Widget")

local function BoxSelect(parameters)
    local parameters = parameters or {}
    local instance = Widget()

    local _x1 = 0
    local _x2 = 0
    local _y1 = 0
    local _y2 = 0
    local _insideColor = parameters.insideColor or {0, 0, 0, 0.3, 0}
    local _edgeColor = parameters.edgeColor or {1, 1, 1, 0.6, 0}
    local _isActive = false

    function instance:startSelection(startingX, startingY)
        _x1 = startingX
        _x2 = startingX
        _y1 = startingY
        _y2 = startingY

        instance:setX(startingX)
        instance:setY(startingY)
        instance:setWidth(0)
        instance:setHeight(0)

        instance:queueRedraw()
    end
    function instance:editSelection(editX, editY)
        _isActive = true
        _x2 = editX
        _y2 = editY

        instance:setX(math.min(_x1, _x2))
        instance:setY(math.min(_y1, _y2))
        instance:setWidth(math.abs(_x1 - _x2))
        instance:setHeight(math.abs(_y1 - _y2))

        instance:queueRedraw()
    end
    function instance:makeSelection(parameters)
        local thingsToSelect = parameters.thingsToSelect
        local isInsideFunction = parameters.isInsideFunction
        local setSelectedFunction = parameters.setSelectedFunction
        local getSelectedFunction = parameters.getSelectedFunction
        local shouldAdd = parameters.shouldAdd
        local shouldInvert = parameters.shouldInvert

        for i = 1, #thingsToSelect do
            local thing = thingsToSelect[i]

            if isInsideFunction(instance, thing) then
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

        _isActive = false
        instance:queueClear()
    end

    function instance:draw()
        local width = instance:getWidth()
        local height = instance:getHeight()

        if _isActive then
            instance:setColor(_edgeColor)
            instance:drawRectangle(0, 0, width, height, false)

            instance:setColor(_insideColor)
            instance:drawRectangle(1, 1, width - 2, height - 2, true)
        end
    end

    return instance
end

return BoxSelect