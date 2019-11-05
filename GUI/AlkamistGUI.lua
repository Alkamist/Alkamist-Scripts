local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local UserControl = require("GUI.UserControl")
local TrackedNumber = require("GUI.TrackedNumber")

local function GUI()
    local gui = {}

    local _title = ""
    local _x = 0
    local _y = 0
    local _width = TrackedNumber(0)
    local _height = TrackedNumber(0)
    local _dock = 0
    local _mouse = UserControl.mouse
    local _keyboard = UserControl.keyboard
    local _backgroundColor = { 0.0, 0.0, 0.0, 1.0, 0 }
    local _widgets = {}

    function gui:getMouse()
        return _mouse
    end
    function gui:getKeyboard()
        return _keyboard
    end
    function gui:getWidgets()
        return _widgets
    end

    function gui:setBackgroundColor(color)
        _backgroundColor = color
        gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
    end
    function gui:windowWasResized()
        return _width:justChanged() or _height:justChanged()
    end
    function gui:addWidgets(widgets)
        for i = 1, #widgets do
            local widget = widgets[i]
            _widgets[#_widgets + 1] = widget
        end
        _mouse:setWidgets(_widgets)
    end

    function gui:initialize(parameters)
        _title = parameters.title or _title or ""
        _x = parameters.x or _x or 0
        _y = parameters.y or _y or 0
        _width:setValue(parameters.width or _width:getValue() or 0)
        _height:setValue(parameters.height or _height:getValue() or 0)
        _dock = parameters.dock or _dock or 0

        gfx.init(_title, _width:getValue(), _height:getValue(), _dock, _x, _y)
    end
    function gui:run()
        _width:update(gfx.w)
        _height:update(gfx.h)
        _mouse:update()
        _keyboard:update()

        local char = _keyboard:getCurrentCharacter()
        if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

        if _widgets then
            local numberOfWidgets = #_widgets
            for i = 1, numberOfWidgets do _widgets[i]:doBeginUpdateFunction() end
            for i = 1, numberOfWidgets do _widgets[i]:doUpdateFunction() end
            for i = 1, numberOfWidgets do
                local widget = _widgets[i]
                if widget.doDrawFunction then widget:doDrawFunction() end
                if widget.blitToMainWindow then widget:blitToMainWindow() end
            end
            for i = 1, numberOfWidgets do _widgets[i]:doEndUpdateFunction() end
        end

        if char ~= "Escape" and char ~= "Close" then reaper.defer(gui.run) end
        gfx.update()
    end

    return gui
end

return GUI()