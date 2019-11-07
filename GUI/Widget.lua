local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Rectangle = require("GUI.Rectangle")
local Drawable = require("GUI.Drawable")

local currentBuffer = -1
local function getNewDrawBuffer()
    currentBuffer = currentBuffer + 1
    if currentBuffer > 1023 then currentBuffer = 0 end
    return currentBuffer
end

local function Widget(parameters, fromObject)
    local parameters = parameters or {}
    parameters.drawBuffer = parameters.drawBuffer or getNewDrawBuffer()

    local instance = Drawable(parameters, fromObject)
    instance.width = parameters.width or 0
    instance.height = parameters.height or 0

    local _GUI = parameters.GUI
    local _mouse = _GUI:getMouse()
    local _keyboard = _GUI:getKeyboard()
    local _shouldClear = false
    local _isVisible = parameters.isVisible
    if _isVisible == nil then _isVisible = true end
    local _shouldRedraw = parameters.shouldRedraw
    if _shouldRedraw == nil then _shouldRedraw = true end
    local _shouldDrawDirectly = false

    function instance:getGUI() return _GUI end
    function instance:getMouse() return _mouse end
    function instance:getKeyboard() return _keyboard end
    function instance:getRelativeMouseX() return instance:getMouse():getX() - instance.x end
    function instance:getRelativeMouseY() return instance:getMouse():getY() - instance.y end
    function instance:getPreviousRelativeMouseX() return instance:getMouse():getPreviousX() - instance.x end
    function instance:getPreviousRelativeMouseY() return instance:getMouse():getPreviousY() - instance.y end
    function instance:shouldRedraw() return _shouldRedraw end
    function instance:shouldClear() return _shouldClear end
    function instance:isVisible() return _isVisible end
    function instance:pointIsInside(pointX, pointY)
        local x = instance.x
        local y = instance.y
        return pointX >= x and pointX <= x + instance.width
           and pointY >= y and pointY <= y + instance.height
    end

    function instance:setVisibility(value) _isVisible = value end
    function instance:toggleVisibility() instance:setVisibility(not instance:isVisible()) end
    function instance:show() instance:setVisibility(true) end
    function instance:hide() instance:setVisibility(false) end
    function instance:queueRedraw() _shouldRedraw = true end
    function instance:queueClear() _shouldClear = true end

    local function _clearBuffer()
        gfx.setimgdim(instance.drawBuffer, -1, -1)
        gfx.setimgdim(instance.drawBuffer, instance.width, instance.height)
    end
    function instance:doBeginUpdateFunction()
        if instance.beginUpdate then instance:beginUpdate() end
    end
    function instance:doUpdateFunction()
        if instance.update then instance:update() end
    end
    function instance:doDrawFunction()
        if instance:shouldRedraw() and instance.draw then
            _clearBuffer()
            gfx.a = 1.0
            gfx.mode = 0
            gfx.dest = instance.drawBuffer
            instance:draw()

        elseif instance:shouldClear() then
            _clearBuffer()
            _shouldClear = false
        end

        _shouldRedraw = false
    end
    function instance:blitToMainWindow()
        if instance:isVisible() then
            local x = instance.x
            local y = instance.y
            local width = instance.width
            local height = instance.height
            gfx.a = 1.0
            gfx.mode = 0
            gfx.dest = -1
            gfx.blit(instance.drawBuffer, 1.0, 0, 0, 0, width, height, x, y, width, height, 0, 0)
        end
    end
    function instance:doEndUpdateFunction()
        if instance.endUpdate then instance:endUpdate() end
    end

    _clearBuffer()
    return instance
end

return Widget