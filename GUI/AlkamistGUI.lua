local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local UserControl = require("GUI.UserControl")
local TrackedNumber = require("GUI.TrackedNumber")

local function GUI()
    local self = {}

    local _title = ""
    local _x = 0
    local _y = 0
    local _width = TrackedNumber(0)
    local _height = TrackedNumber(0)
    local _dock = 0
    local _mouse = UserControl.mouse
    local _keyboard = UserControl.keyboard
    local _backgroundColor = {}
    local _elements = {}
    local _currentBuffer = -1

    function self.getElements()
        return _elements
    end

    function self.setBackgroundColor(color)
        _backgroundColor = color
        gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
    end
    function self.windowWasResized()
        return _width.justChanged() or _height.justChanged()
    end
    function self.getNewDrawBuffer()
        _currentBuffer = _currentBuffer + 1
        if _currentBuffer > 1023 then _currentBuffer = 0 end
        return _currentBuffer
    end
    function self.addElements(elements)
        for i = 1, #elements do
            local element = elements[i]
            _elements[#_elements + 1] = element
        end
    end

    function self.initialize(parameters)
        _title = parameters.title or _title or ""
        _x = parameters.x or _x or 0
        _y = parameters.y or _y or 0
        _width.setValue(parameters.width or _width.getValue() or 0)
        _height.setValue(parameters.height or _height.getValue() or 0)
        _dock = parameters.dock or _dock or 0

        gfx.init(_title, _width.getValue(), _height.getValue(), _dock, _x, _y)
    end
    function self.run()
        _width.update(gfx.w)
        _height.update(gfx.h)

        _mouse.update()
        _keyboard.update()

        local char = _keyboard.getCurrentCharacter()
        if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

        --if _elements then
        --    for i = 1, #_elements do
        --        local element = _elements[i]
        --        element.updateElementStates()
        --    end
        --    for i = 1, #_elements do
        --        local element = _elements[i]
        --        element.updateElement()
        --    end
        --    for i = 1, #_elements do
        --        local element = _elements[i]
        --        element.drawElement()
        --    end
        --    for i = 1, #_elements do
        --        local element = _elements[i]
        --        element.blitElement()
        --    end
        --end

        if char ~= "Escape" and char ~= "Close" then reaper.defer(self.run) end
        gfx.update()
    end

    return self
end

return GUI()