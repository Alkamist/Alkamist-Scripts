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
        default = { 0.0, 0.0, 0.0, 1.0, 0 },
        set = function(self, color)
            self.backgroundColor = color
            gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
        end
    },
    windowWasResized = { get = function(self) return self.widthJustChanged or self.heightJustChanged end },
    widgets = {
        default = {},
        set = function(self, value)
            self.widgets = value
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
    local self = gui
    self.widthTracker:update(gfx.w)
    self.heightTracker:update(gfx.h)
    self.mouse:update()
    self.keyboard:update()

    local char = self.keyboard.currentCharacter
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    --msg(self.windowWasResized)
    --if self.windowWasResized then msg("yee") end
    --if self.mouse.leftButton.isPressed then msg("left") end

    --local widgets = self.widgets
    --if widgets then
    --    local numberOfWidgets = #widgets
    --    for i = 1, numberOfWidgets do widgets[i]:doBeginUpdateFunction() end
    --    for i = 1, numberOfWidgets do widgets[i]:doUpdateFunction() end
    --    for i = 1, numberOfWidgets do
    --        local widget = widgets[i]
    --        if widget.doDrawFunction then widget:doDrawFunction() end
    --        if widget.blitToMainWindow then widget:blitToMainWindow() end
    --    end
    --    for i = 1, numberOfWidgets do widgets[i]:doEndUpdateFunction() end
    --end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(self.run) end
    gfx.update()
end

return gui