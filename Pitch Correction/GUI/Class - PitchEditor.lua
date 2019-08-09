if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end

local PitchPoint = require "Classes.Class - PitchPoint"

GUI.PitchEditor = GUI.Element:new()
function GUI.PitchEditor:new(name, z, x, y, w, h)
    -- This provides support for creating elms with a keyed table
    local object = (not x and type(z) == "table") and z or {}

    object.name = name
    object.type = "PitchEditor"

    object.z = object.z or z


    object.x = object.x or x
    object.y = object.y or y

    object.w = GUI.w - 4
    object.h = GUI.h - object.y - 2

    object.orig_w = object.w
    object.orig_h = object.h

    object.take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))
    object.item = reaper.GetMediaItemTake_Item(object.take)
    object.takeGUID = reaper.BR_GetMediaItemTakeGUID(object.take)
    object.pitchPoints = PitchPoint.getPitchPoints(object.takeGUID)

    object.zoomX = 1.0
    object.zoomY = 1.0

    object.scrollX = 0.0
    object.scrollY = 0.0

    GUI.redraw_z[z] = true

    setmetatable(object, self)
    self.__index = self
    return object
end

function GUI.PitchEditor:init()
    local x, y, w, h = self.x, self.y, self.w, self.h

    -- Pretty much any class will benefit from doing as much drawing as possible
    -- to a buffer, so the GUI can just copy/paste it when the screen updates rather
    -- than getting each element to redraw itself every single time.

    -- Seriously, redrawing can eat up a TON of CPU.

    self.buff = self.buff or GUI.GetBuffer()

    gfx.dest = self.buff
    gfx.setimgdim(self.buff, -1, -1)
    gfx.setimgdim(self.buff, w, h)

    GUI.color("elm_bg")
    gfx.rect(0, 0, w, h, 1)

    self:drawpitchlines()

    self:redraw()
end

function GUI.PitchEditor:draw()
    local x, y, w, h = self.x, self.y, self.w, self.h

    -- Copy the pre-drawn bits
    gfx.blit(self.buff, 1, 0, 0, 0, self.orig_w, self.orig_h, x, y, w, h)
    gfx.blit(self.pitchLinesBuff, 1, 0, 0, 0, w, h, x, y)

    -- Draw text, or whatever you want, here
end

function GUI.PitchEditor:onmousedown()
    -- Odds are, any input method will want to make the element redraw itself so
    -- whatever the user did is actually shown on the screen.
    self:redraw()
end

function GUI.PitchEditor:ondrag()
    -- GUI.mouse.ox and .oy are available to compare where the drag started from
    -- with the current position
    --GUI.color("red")
    --gfx.line(GUI.mouse.ox, GUI.mouse.oy, GUI.mouse.x, GUI.mouse.y, true)

    self:redraw()
end

function GUI.PitchEditor:onresize()
    self.w = GUI.cur_w - 4
    self.h = GUI.cur_h - self.y - 2

    self:drawpitchlines()

    self:redraw()
end

function GUI.PitchEditor:ondelete()
    GUI.FreeBuffer(self.buff)
end

function GUI.PitchEditor:drawpitchlines()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local windowStep = 0.04
    local overlap = 2
    local drawThreshold = 2.5 * windowStep / overlap

    local itemLength = reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")

    self.pitchLinesBuff = self.pitchLinesBuff or GUI.GetBuffer()

    gfx.dest = self.pitchLinesBuff
    gfx.setimgdim(self.pitchLinesBuff, -1, -1)
    gfx.setimgdim(self.pitchLinesBuff, w, h)

    GUI.color("green")

    local previousPoint = nil
    local previousPointX = 0
    local previousPointY = 0
    for pointKey, point in PitchPoint.pairs(self.pitchPoints) do
        local pointX = w * point.time / itemLength
              pointX = self.zoomX * (pointX - w * self.scrollX)
              pointX = GUI.round(pointX)

        local pointY = h * (1.0 - point.pitch / 127)
              pointY = self.zoomY * (pointY - h * self.scrollY)
              pointY = GUI.round(pointY)

        if pointKey == 1 then
            previousPoint = point
            previousPointX = pointX
            previousPointY = pointY
        end

        if point.time - previousPoint.time > drawThreshold then
            previousPointX = pointX
            previousPointY = pointY
        end

        gfx.line(previousPointX, previousPointY, pointX, pointY, false)

        previousPoint = point
        previousPointX = pointX
        previousPointY = pointY
    end

    self:redraw()
end