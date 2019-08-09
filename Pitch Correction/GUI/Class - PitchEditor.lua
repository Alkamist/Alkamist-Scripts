if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end

local PitchPoint = require "Classes.Class - PitchPoint"

GUI.PitchEditor = GUI.Element:new()
function GUI.PitchEditor:new(name, z, x, y, w, h, take)
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

    object.zoomX = 1.0
    object.zoomY = 1.0

    object.scrollX = 0.0
    object.scrollY = 0.0

    object.zoomXPreDrag = 1.0
    object.scrollXPreDrag = 0.0

    object.zoomYPreDrag = 1.0
    object.scrollXPreDrag = 1.0

    object.mousePrev = {}
    object.mousePrev.x = 0
    object.mousePrev.y = 0

    GUI.redraw_z[z] = true

    setmetatable(object, self)
    self.__index = self

    object:setTake(object.take or take)

    return object
end

function GUI.PitchEditor:init()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self:drawBackground()
    self:drawPitchLines()

    self:redraw()
end

function GUI.PitchEditor:draw()
    local x, y, w, h = self.x, self.y, self.w, self.h

    if self.backgroundBuff then
        gfx.blit(self.backgroundBuff, 1, 0, 0, 0, self.orig_w, self.orig_h, x, y, w, h)
    end

    if self.pitchLinesBuff then
        gfx.blit(self.pitchLinesBuff, 1, 0, 0, 0, w, h, x, y)
    end

    self.mousePrev.x = GUI.mouse.x
    self.mousePrev.y = GUI.mouse.y
end

function GUI.PitchEditor:onmousedown()
    self.scrollXPreDrag = self.scrollX
    self.zoomXPreDrag = self.zoomX

    self.scrollYPreDrag = self.scrollY
    self.zoomYPreDrag = self.zoomY

    self:redraw()
end

function GUI.PitchEditor:ondrag()
    local x, y, w, h = self.x, self.y, self.w, self.h
    local zoomXSens = 4.0
    local zoomYSens = 4.0


    -- Horizontal zoom:
    self.zoomX = self.zoomX * (1.0 + zoomXSens * (GUI.mouse.x - self.mousePrev.x) / w)

    local targetMouseXRatio = self.scrollXPreDrag + GUI.mouse.ox / (w * self.zoomXPreDrag)
    self.scrollX = targetMouseXRatio - GUI.mouse.ox / (w * self.zoomX)


    -- Vertical zoom:
    self.zoomY = self.zoomY * (1.0 + zoomYSens * (GUI.mouse.y - self.mousePrev.y) / h)

    local targetMouseYRatio = self.scrollYPreDrag + GUI.mouse.oy / (h * self.zoomYPreDrag)
    self.scrollY = targetMouseYRatio - GUI.mouse.oy / (h * self.zoomY)



    self:drawPitchLines()

    self:redraw()
end

function GUI.PitchEditor:onresize()
    self.w = GUI.cur_w - 4
    self.h = GUI.cur_h - self.y - 2

    self:drawPitchLines()

    self:redraw()
end

function GUI.PitchEditor:ondelete()
    GUI.FreeBuffer(self.backgroundBuff)
end

function GUI.PitchEditor:drawBackground()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self.backgroundBuff = self.backgroundBuff or GUI.GetBuffer()

    gfx.dest = self.backgroundBuff
    gfx.setimgdim(self.backgroundBuff, -1, -1)
    gfx.setimgdim(self.backgroundBuff, w, h)

    GUI.color("elm_bg")
    gfx.rect(0, 0, w, h, 1)
end

function GUI.PitchEditor:drawPitchLines()
    if self.take == nil then return end

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
        local pointXRatio = point.time / itemLength
        local pointX = GUI.round( self.zoomX * w * (pointXRatio - self.scrollX) )

        local pointYRatio = 1.0 - point.pitch / 127
        local pointY = GUI.round( self.zoomY * h * (pointYRatio - self.scrollY) )

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

function GUI.PitchEditor:setTake(take)
    self.take = take
    self.item = reaper.GetMediaItemTake_Item(take)
    self.takeGUID = reaper.BR_GetMediaItemTakeGUID(take)
    self.pitchPoints = PitchPoint.getPitchPoints(self.takeGUID)
end