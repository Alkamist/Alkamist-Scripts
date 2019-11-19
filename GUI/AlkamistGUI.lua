local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local UserControl = require("GUI.UserControl")
local TrackedNumber = require("GUI.TrackedNumber")

local GUI = {}

function GUI:new()
    local self = {}

    local _title = ""
    local _x = 0
    local _y = 0
    local _widthTracker = TrackedNumber:new()
    local _heightTracker = TrackedNumber:new()
    local _dock = 0
    local _backgroundColor = { 0.0, 0.0, 0.0, 1.0, 0 }
    local _widgets = {}
    local _bufferIsUsed = {}
    local _mouse = UserControl:getMouse()
    local _keyboard = UserControl:getKeyboard()

    function self:getWidgets() return _widgets end
    function self:setWidgets(widgets)
        for i = 1, #widgets do
            _widgets[i] = widgets[i]
        end
        _mouse:setWidgets(widgets)
    end
    function self:getMouse() return _mouse end
    function self:getKeyboard() return _keyboard end
    function self:getX() return _x end
    function self:setX(value) _x = value end
    function self:getY() return _y end
    function self:setY(value) _y = value end
    function self:getWidth() return _widthTracker:getValue() end
    function self:setWidth(value) _widthTracker:setValue(value) end
    function self:getPreviousWidth() return _widthTracker:getPreviousValue() end
    function self:getWidthChange() return _widthTracker:getChange() end
    function self:widthJustChanged() return _widthTracker:justChanged() end
    function self:getHeight() return _heightTracker:getValue() end
    function self:setHeight(value) _heightTracker:setValue(value) end
    function self:getPreviousHeight() return _heightTracker:getPreviousValue() end
    function self:getHeightChange() return _heightTracker:getChange() end
    function self:heightJustChanged() return _heightTracker:justChanged() end
    function self:windowWasResized() return self:heightJustChanged() or self:widthJustChanged() end
    function self:getNewDrawBuffer()
        for i = 0, 1023 do
            if not _bufferIsUsed[i] then
                _bufferIsUsed[i] = true
                return i
            end
        end
    end
    function self:setBackgroundColor(color)
        _backgroundColor = color
        gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
    end
    function self:initialize(parameters)
        local parameters = parameters or {}
        _title = parameters.title or _title or ""
        self:setX(parameters.x or self:getX() or 0)
        self:setY(parameters.y or self:getY() or 0)
        self:setWidth(parameters.width or self:getWidth() or 0)
        self:setHeight(parameters.height or self:getHeight() or 0)
        _dock = parameters.dock or _dock or 0
        gfx.init(_title, self:getWidth(), self:getHeight(), _dock, self:getX(), self:getY())
    end
    function self:update()
        _widthTracker:update(gfx.w)
        _heightTracker:update(gfx.h)
        _mouse:update()
        _keyboard:update()
    end

    return self
end

local gui = GUI:new()
local keyboard = gui:getKeyboard()

function gui:run()
    gui:update()
    local char = keyboard:getCurrentCharacter()
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    local widgets = gui:getWidgets()
    local numberOfWidgets = #widgets
    for i = 1, numberOfWidgets do widgets[i]:doBeginUpdate() end
    for i = 1, numberOfWidgets do widgets[i]:doUpdate() end
    for i = 1, numberOfWidgets do widgets[i]:doDrawToBuffer() end
    for i = 1, numberOfWidgets do widgets[i]:doDrawToParent() end
    for i = 1, numberOfWidgets do widgets[i]:doEndUpdate() end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(gui.run) end
    gfx.update()
end

return gui