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
    widthTracker = TrackedNumber,
    width = {
        get = function(self) return self.widthTracker.currentValue end,
        set = function(self, value) self.widthTracker.currentValue = value end
    },
    widthChange = { get = function(self) return self.widthTracker.change end },
    widthJustChanged = { get = function(self) return self.widthTracker.justChanged end },
    heightTracker = TrackedNumber,
    height = {
        get = function(self) return self.heightTracker.currentValue end,
        set = function(self, value) self.heightTracker.currentValue = value end
    },
    heightChange = { get = function(self) return self.heightTracker.change end },
    heightJustChanged = { get = function(self) return self.heightTracker.justChanged end },
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
            field.value = value
            self.mouse.widgets = field.value
        end
    },
    bufferIsUsed = {},
    getNewDrawBuffer = function(self)
        for i = 0, 1023 do
            if not self.bufferIsUsed[i] then
                self.bufferIsUsed[i] = true
                return i
            end
        end
    end,
    beginUpdateWidget = function(self, widget)
        widget:prepareBeginUpdate()
        if widget.beginUpdate then widget:beginUpdate() end
        local childWidgets = widget.widgets
        if childWidgets then
            for i = 1, #childWidgets do
                self:beginUpdateWidget(childWidgets[i])
            end
        end
    end,
    updateWidget = function(self, widget)
        widget:prepareUpdate()
        if widget.update then widget:update() end
        local childWidgets = widget.widgets
        if childWidgets then
            for i = 1, #childWidgets do
                self:updateWidget(childWidgets[i])
            end
        end
    end,
    drawWidget = function(self, widget)
        widget:prepareDraw()
        if widget.draw then widget:draw() end
        local childWidgets = widget.widgets
        if childWidgets then
            for i = 1, #childWidgets do
                self:drawWidget(childWidgets[i])
            end
        end
        widget:blit()
    end,
    endUpdateWidget = function(self, widget)
        widget:prepareEndUpdate()
        if widget.endUpdate then widget:endUpdate() end
        local childWidgets = widget.widgets
        if childWidgets then
            for i = 1, #childWidgets do
                self:endUpdateWidget(childWidgets[i])
            end
        end
    end
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
    for i = 1, numberOfWidgets do gui:beginUpdateWidget(widgets[i]) end
    for i = 1, numberOfWidgets do gui:updateWidget(widgets[i]) end
    for i = 1, numberOfWidgets do gui:drawWidget(widgets[i]) end
    for i = 1, numberOfWidgets do gui:endUpdateWidget(widgets[i]) end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(gui.run) end
    gfx.update()
end

return gui