if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end



local PitchPoint = require "Classes.Class - PitchPoint"

GUI.colors["white_keys"] = {112, 112, 112, 255}
GUI.colors["black_keys"] = {81, 81, 81, 255}

GUI.colors["white_key_bg"] = {59, 59, 59, 255}
GUI.colors["black_key_bg"] = {50, 50, 50, 255}

GUI.colors["white_key_lines"] = {65, 65, 65, 255}
GUI.colors["key_lines"] = {255, 255, 255, 255}

local whiteKeysMultiples = {1, 3, 4, 6, 8, 9, 11}
local whiteKeys = {}
for i = 1, 11 do
    for _, value in ipairs(whiteKeysMultiples) do
        table.insert(whiteKeys, (i - 1) * 12 + value)
    end
end



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

    self:drawKeyBackgrounds()
    self:drawBackground()
    self:drawKeyLines()
    self:drawPitchLines()
    self:drawKeys()

    self:redraw()
end

function GUI.PitchEditor:draw()
    local x, y, w, h = self.x, self.y, self.w, self.h

    if self.backgroundBuff then
        gfx.blit(self.backgroundBuff, 1, 0, 0, 0, self.orig_w, self.orig_h, x, y, w, h)
    end

    if self.keyBackgroundBuff then
        gfx.blit(self.keyBackgroundBuff, 1, 0, 0, 0, w, h, x, y)
    end

    if self.keyLinesBuff then
        gfx.blit(self.keyLinesBuff, 1, 0, 0, 0, w, h, x, y)
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

function GUI.PitchEditor:onmouseup()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local itemLength = reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")
    local itemLeftBound = reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")

    local playTime = itemLeftBound + itemLength * GUI.mouse.x / w
    reaper.SetEditCurPos(playTime, true, true)

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
        self.scrollX = GUI.clamp(self.scrollX, 0.0, scrollXMax)

        -- Vertical scroll:
        self.scrollY = self.scrollY - (GUI.mouse.y - self.mousePrev.y) / (h * self.zoomY)
        self.scrollY = GUI.clamp(self.scrollY, 0.0, scrollYMax)

        self:drawKeyBackgrounds()
        self:drawKeyLines()
        self:drawPitchLines()
        self:drawKeys()

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
        local scrollXMax = 1.0 - w / (w * self.zoomX)
        local scrollYMax = 1.0 - h / (h * self.zoomY)

        -- Horizontal zoom:
        self.zoomX = self.zoomX * (1.0 + zoomXSens * (GUI.mouse.x - self.mousePrev.x) / w)
        self.zoomX = GUI.clamp(self.zoomX, 1.0, 100.0)

        local targetMouseXRatio = self.scrollXPreDrag + self.mouseXPreDrag / (w * self.zoomXPreDrag)
        self.scrollX = targetMouseXRatio - self.mouseXPreDrag / (w * self.zoomX)
        self.scrollX = GUI.clamp(self.scrollX, 0.0, scrollXMax)

        -- Vertical zoom:
        self.zoomY = self.zoomY * (1.0 + zoomYSens * (GUI.mouse.y - self.mousePrev.y) / h)
        self.zoomY = GUI.clamp(self.zoomY, 1.0, 100.0)

        local targetMouseYRatio = self.scrollYPreDrag + self.mouseYPreDrag / (h * self.zoomYPreDrag)
        self.scrollY = targetMouseYRatio - self.mouseYPreDrag / (h * self.zoomY)
        self.scrollY = GUI.clamp(self.scrollY, 0.0, scrollYMax)

        self:drawKeyBackgrounds()
        self:drawKeyLines()
        self:drawPitchLines()
        self:drawKeys()

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

    self:drawKeyBackgrounds()
    self:drawKeyLines()
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

function GUI.PitchEditor:drawKeyBackgrounds()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local keyWidth = w * 0.05
    local keyHeight = self.zoomY * h * 1.0 / 127.0

    local scrollOffset = self.scrollY * h * self.zoomY

    self.keyBackgroundBuff = self.keyBackgroundBuff or GUI.GetBuffer()

    gfx.dest = self.keyBackgroundBuff
    gfx.setimgdim(self.keyBackgroundBuff, -1, -1)
    gfx.setimgdim(self.keyBackgroundBuff, w, h)

    for i = 1, 127 do
        GUI.color("black_key_bg")

        for _, value in ipairs(whiteKeys) do
            if i == value then
                GUI.color("white_key_bg")
            end
        end

        gfx.rect(0, (i - 1) * keyHeight - scrollOffset, w, keyHeight + 1, 1)

        GUI.color("black_key_bg")

        gfx.line(0, i * keyHeight - scrollOffset - 1, w, i * keyHeight - scrollOffset - 1, false)
    end

    self:redraw()
end

function GUI.PitchEditor:drawKeyLines()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local keyHeight = self.zoomY * h * 1.0 / 127.0

    local scrollOffset = self.scrollY * h * self.zoomY

    self.keyLinesBuff = self.keyLinesBuff or GUI.GetBuffer()

    gfx.dest = self.keyLinesBuff
    gfx.setimgdim(self.keyLinesBuff, -1, -1)
    gfx.setimgdim(self.keyLinesBuff, w, h)

    if keyHeight > 16 then
        for i = 1, 127 do
            GUI.color("key_lines")

            local keyLineHeight = i * keyHeight - scrollOffset - keyHeight * 0.5 - 1

            gfx.a = 0.3
            gfx.line(0, keyLineHeight, w, keyLineHeight, false)
            gfx.a = 1
        end
    end

    self:redraw()
end

function GUI.PitchEditor:drawKeys()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local keyWidth = w * 0.05
    local keyHeight = self.zoomY * h * 1.0 / 127.0

    local scrollOffset = self.scrollY * h * self.zoomY

    self.keysBuff = self.keysBuff or GUI.GetBuffer()

    gfx.dest = self.keysBuff
    gfx.setimgdim(self.keysBuff, -1, -1)
    gfx.setimgdim(self.keysBuff, w, h)

    for i = 1, 127 do
        GUI.color("black_keys")

        for _, value in ipairs(whiteKeys) do
            if i == value then
                GUI.color("white_keys")
            end
        end

        gfx.rect(0, (i - 1) * keyHeight - scrollOffset, keyWidth, keyHeight + 1, 1)

        GUI.color("black_keys")

        gfx.line(0, i * keyHeight - scrollOffset - 1, keyWidth - 1, i * keyHeight - scrollOffset - 1, false)
    end

    self:redraw()
end

function GUI.PitchEditor:setTake(take)
    self.take = take
    self.item = reaper.GetMediaItemTake_Item(take)
    self.takeGUID = reaper.BR_GetMediaItemTakeGUID(take)
    self.pitchPoints = PitchPoint.getPitchPoints(self.takeGUID)

    self:drawPitchLines()

    self:redraw()
end