local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Prototype = require("Prototype")
local UserControl = require("GUI.UserControl")
local TrackedNumber = require("GUI.TrackedNumber")

local function addWidgetToTable(t, widget)
    if widget.widgets and #widget.widgets > 0 then
        local childWidgets = widget.widgets
        for i = 1, #childWidgets do
            addWidgetToTable(t, childWidgets[i])
        end
    else
        t[#t + 1] = widget
    end
end

local GUI = Prototype:new{
    title = "",
    x = 0,
    y = 0,
    widthTracker = TrackedNumber:new(),
    width = {
        get = function(self) return self.widthTracker.currentValue end,
        set = function(self, value) self.widthTracker.currentValue = value end
    },
    widthChange = { get = function(self) return self.widthTracker.change end },
    widthJustChanged = { get = function(self) return self.widthTracker.justChanged end },
    heightTracker = TrackedNumber:new(),
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
            for i = 1, #value do
                local widget = value[i]
                addWidgetToTable(field.value, widget)
            end
            self.mouse.widgets = field.value
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
    for i = 1, numberOfWidgets do if widgets[i].beginUpdate then widgets[i]:beginUpdate() end end
    for i = 1, numberOfWidgets do if widgets[i].update then widgets[i]:update() end end
    for i = 1, numberOfWidgets do
        local widget = widgets[i]
        if widget.draw then
            --if widget.shouldDrawDirectly or widget.shouldRedraw then
            --    widget:clearBuffer()
                gfx.a = 1.0
                gfx.mode = 0
                gfx.dest = widget.drawBuffer
                widget:draw()
            --    widget.shouldRedraw = false
            --end
        --elseif widget.shouldClear then
        --    widget:clearBuffer()
        --    widget.shouldClear = false
        end
        --if widget.isVisible and not widget.shouldDrawDirectly then
        --    local x = widget.x
        --    local y = widget.y
        --    local width = widget.width
        --    local height = widget.height
        --    gfx.a = 1.0
        --    gfx.mode = 0
        --    gfx.dest = -1
        --    gfx.blit(widget.drawBuffer, 1.0, 0, 0, 0, width, height, x, y, width, height, 0, 0)
        --end
    end
    for i = 1, numberOfWidgets do if widgets[i].endUpdate then widgets[i]:endUpdate() end end

    if char ~= "Escape" and char ~= "Close" then reaper.defer(gui.run) end
    gfx.update()
end

return gui