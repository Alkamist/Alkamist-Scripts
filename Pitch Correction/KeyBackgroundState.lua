local GUI = require("GUI")

local reaper = reaper

local math = math
local floor = math.floor
local ceil = math.ceil

local function round(number) return number > 0 and floor(number + 0.5) or ceil(number - 0.5) end
local function pixelsToTime(self, pixels) return self.timeLength * (self.xScroll + pixels / (self.width * self.xZoom)) end
local function timeToPixels(self, time) return self.xZoom * self.width * (time / self.timeLength - self.xScroll) end
local function pixelsToPitch(self, pixels) return self.pitchHeight * (1.0 - (self.yScroll + pixels / (self.height * self.yZoom))) - 0.5 end
local function pitchToPixels(self, pitch) return self.yZoom * self.height * ((1.0 - (0.5 + pitch) / self.pitchHeight) - self.yScroll) end
local function getNewScroll(change, zoom, scroll, scale) return scroll - change / (zoom * scale) end
local function changeXScroll(self, change) self.xScroll = getNewScroll(change, self.xZoom, self.xScroll, self.width) end
local function changeYScroll(self, change) self.yScroll = getNewScroll(change, self.yZoom, self.yScroll, self.height) end
local function getNewZoomAndScroll(change, zoom, scroll, target, scale)
    local target = target / scale
    local sensitivity = 0.01
    local change = 2 ^ (sensitivity * change)
    local zoom = zoom * change
    local scroll = scroll + (change - 1.0) * target / zoom
    return zoom, scroll
end
local function changeXZoom(self, change) self.xZoom, self.xScroll = getNewZoomAndScroll(change, self.xZoom, self.xScroll, self.xTarget, self.width) end
local function changeYZoom(self, change) self.yZoom, self.yScroll = getNewZoomAndScroll(change, self.yZoom, self.yScroll, self.yTarget, self.height) end

local KeyBackgroundState = {}

function KeyBackgroundState:requires()
    return self.KeyBackgroundState
end
function KeyBackgroundState:getDefaults()
    local defaults = {}
    defaults.x = 0
    defaults.y = 0
    defaults.width = 0
    defaults.height = 0
    defaults.xZoom = 1.0
    defaults.xScroll = 0.0
    defaults.xTarget = 0.0
    defaults.yZoom = 1.0
    defaults.yScroll = 0.0
    defaults.yTarget = 0.0
    defaults.timeLength = 0.0
    defaults.timeStart = 0.0
    defaults.pitchHeight = 128
    return defaults
end
function KeyBackgroundState:update()
    local selectedItem = reaper.GetSelectedMediaItem(0, 0)
    --self.take = reaper.GetActiveTake(selectedItem)
    if selectedItem then
        self.timeStart = reaper.GetMediaItemInfo_Value(selectedItem, "D_POSITION")
        self.timeLength = reaper.GetMediaItemInfo_Value(selectedItem, "D_LENGTH")
    else
        self.timeStart = 0
        self.timeLength = 0
    end

    self.relativeMouseX = GUI.mouseX - self.x
    self.relativeMouseY = GUI.mouseY - self.y
    self.mouseTime = pixelsToTime(self, self.relativeMouseX)
    self.snappedMouseTime = round(self.mouseTime)
    self.mousePitch = pixelsToPitch(self, self.relativeMouseY)
    self.snappedMousePitch = round(self.mousePitch)

    if GUI.windowWasJustResized then
        self.width = self.width + GUI.windowWidthChange
        self.height = self.height + GUI.windowHeightChange
    end
    if GUI.leftMouseButtonJustPressed then
        self.mouseTimeOnLeftDown = self.mouseTime
        self.mousePitchOnLeftDown = self.mousePitch
        self.snappedMousePitchOnLeftDown = self.snappedMousePitch
    end
    if GUI.middleMouseButtonJustPressed then
        self.xTarget = self.relativeMouseX
        self.yTarget = self.relativeMouseY
    end
    if GUI.middleMouseButtonJustDragged then
        if GUI.shiftKeyIsPressed then
            changeXZoom(self, GUI.mouseXChange)
            changeYZoom(self, GUI.mouseYChange)
        else
            changeXScroll(self, GUI.mouseXChange)
            changeYScroll(self, GUI.mouseYChange)
        end
    end
    if GUI.mouseWheelJustMoved then
        local xSensitivity = 55.0
        local ySensitivity = 55.0

        self.xTarget = self.relativeMouseX
        self.yTarget = self.relativeMouseY

        if GUI.controlKeyIsPressed then
            changeYZoom(self, GUI.mouseWheel * ySensitivity)
        else
            changeXZoom(self, GUI.mouseWheel * xSensitivity)
        end
    end
end

return KeyBackgroundState