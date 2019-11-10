local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local UserControl = require("GUI.UserControl")
local TrackedNumber = require("GUI.TrackedNumber")

local GUI = {}
GUI.title = ""
GUI.x = 0
GUI.y = 0
GUI.widthTracker = TrackedNumber:new()
GUI.width = { from = "widthTracker.currentValue" }
GUI.widthChange = { from = "widthTracker.change" }
GUI.widthJustChanged = { from = "widthTracker.justChanged" }
GUI.heightTracker = TrackedNumber:new()
GUI.height = { from = "heightTracker.currentValue" }
GUI.heightChange = { from = "heightTracker.change" }
GUI.heightJustChanged = { from = "heightTracker.justChanged" }
GUI.dock = 0
GUI.mouse = UserControl.mouse
GUI.keyboard = UserControl.keyboard
GUI.backgroundColor = { 0.0, 0.0, 0.0, 1.0, 0 }
GUI.listOfWidgets = {}
GUI.widgets = {
    get = function(self) return self.listOfWidgets end,
    set = function(self, value)
        self.listOfWidgets = value
        self.mouse.widgets = value
    end
}

function GUI:setBackgroundColor(color)
    self.backgroundColor = color
    gfx.clear = color[1] * 255 + color[2] * 255 * 256 + color[3] * 255 * 65536
end
function GUI:windowWasResized()
    return self.widthJustChanged or self.heightJustChanged
end

function GUI:initialize(parameters)
    self.title = parameters.title or self.title or ""
    self.x = parameters.x or self.x or 0
    self.y = parameters.y or self.y or 0
    self.width = parameters.width or self.width or 0
    self.height = parameters.height or self.height or 0
    self.dock = parameters.dock or self.dock or 0
    gfx.init(self.title, self.width, self.height, self.dock, self.x, self.y)
end
function GUI:run()
    local self = GUI
    self.widthTracker:update(gfx.w)
    self.heightTracker:update(gfx.h)
    self.mouse:update()
    self.keyboard:update()

    local char = self.keyboard.currentCharacter
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

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

    if char ~= "Escape" and char ~= "Close" then reaper.defer(GUI.run) end
    gfx.update()
end

return Proxy:createPrototype(GUI):new()