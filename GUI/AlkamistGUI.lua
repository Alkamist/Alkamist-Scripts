local reaper = reaper
local gfx = gfx

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Proxy = require("Proxy")
local UserControl = require("GUI.UserControl")
local TrackedNumber = require("GUI.TrackedNumber")

local GUI = {}
function GUI:new(initialValues)
    local self = {}

    self.title = ""
    self.x = 0
    self.y = 0
    self.widthTracker = TrackedNumber:new()
    self.width = {
        get = function(self) return self.widthTracker.currentValue end,
        set = function(self, value) self.widthTracker.currentValue = value end
    }
    self.widthChange = { get = function(self) return self.widthTracker.change end }
    self.widthJustChanged = { get = function(self) return self.widthTracker.justChanged end }
    self.heightTracker = TrackedNumber:new()
    self.height = {
        get = function(self) return self.heightTracker.currentValue end,
        set = function(self, value) self.heightTracker.currentValue = value end
    }
    self.heightChange = { get = function(self) return self.heightTracker.change end }
    self.heightJustChanged = { get = function(self) return self.heightTracker.justChanged end }
    self.dock = 0
    self.mouse = UserControl.mouse
    self.keyboard = UserControl.keyboard
    self.backgroundColor = {
        value = { 0.0, 0.0, 0.0, 1.0, 0 },
        set = function(self, value, field)
            field.value = value
            gfx.clear = value[1] * 255 + value[2] * 255 * 256 + value[3] * 255 * 65536
        end,
        get = function(self, field) return field.value end
    }
    self.windowWasResized = { get = function(self) return self.widthJustChanged or self.heightJustChanged end }
    self.widgets = {
        value = {},
        get = function(self, field) return field.value end,
        set = function(self, value, field)
            field.value = value
            self.mouse.widgets = field.value
        end
    }

    self.bufferIsUsed = {}
    function self:getNewDrawBuffer()
        for i = 0, 1023 do
            if not self.bufferIsUsed[i] then
                self.bufferIsUsed[i] = true
                return i
            end
        end
    end

    function self:initialize(parameters)
        local parameters = parameters or {}
        self.title = parameters.title or self.title or ""
        self.x = parameters.x or self.x or 0
        self.y = parameters.y or self.y or 0
        self.width = parameters.width or self.width or 0
        self.height = parameters.height or self.height or 0
        self.dock = parameters.dock or self.dock or 0
        gfx.init(self.title, self.width, self.height, self.dock, self.x, self.y)
    end

    return Proxy:new(self, initialValues)
end

local gui = GUI:new()

function gui:run()
    gui.widthTracker:update(gfx.w)
    gui.heightTracker:update(gfx.h)
    gui.mouse:update()
    gui.keyboard:update()

    local char = gui.keyboard.currentCharacter
    if char == "Space" then reaper.Main_OnCommandEx(40044, 0, 0) end

    local widgets = gui.widgets
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