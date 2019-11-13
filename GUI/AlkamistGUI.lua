local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")
local UserControl = require("GUI.UserControl")
local TrackedNumber = require("GUI.TrackedNumber")

local GUI = Prototype:new{
    title = "",
    x = 0,
    y = 0,
    widthTracker = TrackedNumber:new(),
    width = { from = { "widthTracker", "currentValue" } },
    widthChange = { from = { "widthTracker", "change" } },
    widthJustChanged = { from = { "widthTracker", "justChanged" } },
    heightTracker = TrackedNumber:new(),
    height = { from = { "heightTracker", "currentValue" } },
    heightChange = { from = { "heightTracker", "change" } },
    heightJustChanged = { from = { "heightTracker", "justChanged" } },
    dock = 0,
    mouse = UserControl.mouse,
    keyboard = UserControl.keyboard,
    backgroundColor = {
        value = { 0.0, 0.0, 0.0, 1.0, 0 },
        set = function(self, value, field)
            field.value = value
            gfx.clear = value[1] * 255 + value[2] * 255 * 256 + value[3] * 255 * 65536
        end,
        get = function(self, field) return field.value end
    },
    windowWasResized = { get = function(self) return self.widthJustChanged or self.heightJustChanged end },
    widgets = {
        value = {},
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            for i = 1, #value do
                value[i].mouse = self.mouse
            end
            field.value = value
            self.mouse.widgets = value
        end
    }
}

local gui = GUI:new()
function gui:initialize(parameters)
    local parameters = parameters or {}
    self.title = parameters.title or self.title or ""
    self.x = parameters.x or self.x or 0
    self.y = parameters.y or self.y or 0
    self.width = parameters.width or self.width or 0
    self.height = parameters.height or self.height or 0
    self.dock = parameters.dock or self.dock or 0
    gfx.init(self.title, self.width, self.height, self.dock, self.x, self.y)
end

function gui:run()
    gui.widthTracker:update(gfx.w)
    gui.heightTracker:update(gfx.h)
    gui.mouse:update()
    gui.keyboard:update()

    local char = gui.keyboard.currentCharacter
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    local widgets = gui.widgets
    local numberOfWidgets = #widgets
    for i = 1, numberOfWidgets do widgets[i]:doBeginUpdateFunction() end
    for i = 1, numberOfWidgets do widgets[i]:doUpdateFunction() end
    for i = 1, numberOfWidgets do
        local widget = widgets[i]
        if widget.doDrawFunction then widget:doDrawFunction() end
    --    if widget.blitToMainWindow then widget:blitToMainWindow() end
    end
    for i = 1, numberOfWidgets do widgets[i]:doEndUpdateFunction() end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(gui.run) end
    gfx.update()
end

return gui