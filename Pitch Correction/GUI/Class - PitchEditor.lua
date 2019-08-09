if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end

local PitchPoint = require "Classes.Class - PitchPoint"

GUI.colors["white_keys"] = {125, 125, 125, 255}


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

    object.shouldZoom = false
    object.shouldDragScroll = false

    object.mouse_cap_prev = gfx.mouse_cap

    GUI.redraw_z[z] = true

    setmetatable(object, self)
    self.__index = self

    object:setTake(object.take or take)

    return object
end

function GUI.PitchEditor:init()
    local x, y, w, h = self.x, self.y, self.w, self.h

    self:drawKeys()
    --self:drawBackground()
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

    if self.keysBuff then
        gfx.blit(self.keysBuff, 1, 0, 0, 0, w, h, x, y)
    end
end

function GUI.PitchEditor:onmousedown()
    self:redraw()
end

function GUI.PitchEditor:handleDragScroll()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local zoomXSens = 4.0
    local zoomYSens = 4.0

    -- Middle mouse down:
    if gfx.mouse_cap & 64 == 64 and self.mouse_cap_prev & 64 ~= 64 then
        if GUI.IsInside(self) then
            self.shouldDragScroll = true

            self.mouseXPreDrag = GUI.mouse.x
            self.scrollXPreDrag = self.scrollX
            self.zoomXPreDrag = self.zoomX

            self.mouseYPreDrag = GUI.mouse.y
            self.scrollYPreDrag = self.scrollY
            self.zoomYPreDrag = self.zoomY
        end
    end

    -- Middle mouse up:
    if gfx.mouse_cap & 64 ~= 64 and self.mouse_cap_prev & 64 == 64 then
        self.shouldDragScroll = false
    end

    if self.shouldDragScroll then
        local scrollXMax = 1.0 - w / (w * self.zoomX)
        local scrollYMax = 1.0 - h / (h * self.zoomY)

        -- Horizontal scroll:
        self.scrollX = self.scrollX - (GUI.mouse.x - self.mousePrev.x) / (w * self.zoomX)
        self.scrollX = GUI.clamp(self.scrollX, 0.0, scrollYMax)

        -- Vertical scroll:
        self.scrollY = self.scrollY - (GUI.mouse.y - self.mousePrev.y) / (h * self.zoomY)
        self.scrollY = GUI.clamp(self.scrollY, 0.0, scrollYMax)

        self:drawPitchLines()

        self:redraw()
    end
end

function GUI.PitchEditor:handleZoom()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local zoomXSens = 4.0
    local zoomYSens = 4.0

    -- Middle mouse down:
    --if gfx.mouse_cap & 64 == 64 and self.mouse_cap_prev & 64 ~= 64 then
    if gfx.mouse_cap & 2 == 2 and self.mouse_cap_prev & 2 ~= 2 then
        if GUI.IsInside(self) then
            self.shouldZoom = true

            self.mouseXPreDrag = GUI.mouse.x
            self.scrollXPreDrag = self.scrollX
            self.zoomXPreDrag = self.zoomX

            self.mouseYPreDrag = GUI.mouse.y
            self.scrollYPreDrag = self.scrollY
            self.zoomYPreDrag = self.zoomY
        end
    end

    -- Middle mouse up:
    --if gfx.mouse_cap & 64 ~= 64 and self.mouse_cap_prev & 64 == 64 then
    if gfx.mouse_cap & 2 ~= 2 and self.mouse_cap_prev & 2 == 2 then
        self.shouldZoom = false
    end

    if self.shouldZoom then
        -- Horizontal zoom:
        self.zoomX = self.zoomX * (1.0 + zoomXSens * (GUI.mouse.x - self.mousePrev.x) / w)

        local targetMouseXRatio = self.scrollXPreDrag + self.mouseXPreDrag / (w * self.zoomXPreDrag)
        self.scrollX = targetMouseXRatio - self.mouseXPreDrag / (w * self.zoomX)

        -- Vertical zoom:
        self.zoomY = self.zoomY * (1.0 + zoomYSens * (GUI.mouse.y - self.mousePrev.y) / h)

        local targetMouseYRatio = self.scrollYPreDrag + self.mouseYPreDrag / (h * self.zoomYPreDrag)
        self.scrollY = targetMouseYRatio - self.mouseYPreDrag / (h * self.zoomY)

        self:drawPitchLines()

        self:redraw()
    end
end

function GUI.PitchEditor:onupdate()
    self:handleDragScroll()
    self:handleZoom()

    self.mousePrev.x = GUI.mouse.x
    self.mousePrev.y = GUI.mouse.y

    self.mouse_cap_prev = gfx.mouse_cap
end

function GUI.PitchEditor:ondrag()
    self:redraw()
end

function GUI.PitchEditor:onresize()
    self.w = GUI.cur_w - 4
    self.h = GUI.cur_h - self.y - 2

    self:drawPitchLines()
    self:drawKeys()

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

    self:redraw()
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

function GUI.PitchEditor:drawKeys()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local keyWidth = w * 0.05
    local keyHeight = h * 1.0 / 127.0

    self.keysBuff = self.keysBuff or GUI.GetBuffer()

    gfx.dest = self.keysBuff
    gfx.setimgdim(self.keysBuff, -1, -1)
    gfx.setimgdim(self.keysBuff, w, h)

    for i = 1, 127 do
        GUI.color("white_keys")
        gfx.rect(0, (i - 1) * keyHeight, keyWidth, keyHeight + 1, 0)
    end

    self:redraw()
end

function GUI.PitchEditor:setTake(take)
    self.take = take
    self.item = reaper.GetMediaItemTake_Item(take)
    self.takeGUID = reaper.BR_GetMediaItemTakeGUID(take)
    self.pitchPoints = PitchPoint.getPitchPoints(self.takeGUID)
end