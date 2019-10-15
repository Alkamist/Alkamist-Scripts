package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end

local Alk = require "API.Alkamist API"

GUI.PitchEditor = GUI.Element:new()
function GUI.PitchEditor:new(name, z, x, y, w, h)
    -- This provides support for creating elms with a keyed table
    local object = (not x and type(z) == "table") and z or {}

    object.name = name
    object.type = "PitchEditor"
    object.z = object.z or z
    object.x = object.x or x
    object.y = object.y or y
    object.focus = true
    GUI.redraw_z[z] = true

    setmetatable(object, self)
    self.__index = self
    return object
end

------------------ Helper Functions ------------------

--function GUI.PitchEditor:validateItems()
--    self.prevNumSelectedItems = self.prevNumSelectedItems or 0
--    if #Alk.selectedItems ~= self.prevNumSelectedItems then
--        for _, item in ipairs(Alk.items) do
--
--        end
--    end
--    self.prevNumSelectedItems = #Alk.selectedItems
--end

function GUI.PitchEditor:getTimeFromPixels(xPixels, zoom, scroll)
    local zoom = zoom or self.zoomX
    local scroll = scroll or self.scrollX

    local relativeX = xPixels - self.x
    return self:getTimeLength() * (scroll + relativeX / (self.w * zoom))
end

function GUI.PitchEditor:getPixelsFromTime(time, zoom, scroll)
    local zoom = zoom or self.zoomX
    local scroll = scroll or self.scrollX

    return self.x + zoom * self.w * (time / self:getTimeLength() - scroll)
end

function GUI.PitchEditor:getPitchFromPixels(yPixels, zoom, scroll)
    local zoom = zoom or self.zoomY
    local scroll = scroll or self.scrollY

    local relativeY = yPixels - self.y
    return self:getMaxPitch() * (1.0 - (scroll + relativeY / (self.h * zoom))) - 0.5
end

function GUI.PitchEditor:getPixelsFromPitch(pitch, zoom, scroll)
    local zoom = zoom or self.zoomY
    local scroll = scroll or self.scrollY

    local pitchRatio = 1.0 - (0.5 + pitch) / self.maxPitch
    return self.y + zoom * self.h * (pitchRatio - scroll)
end

function GUI.PitchEditor:calculateWhiteKeys()
    local whiteKeysMultiples = {1, 3, 4, 6, 8, 9, 11}
    self.whiteKeys = {}
    for i = 1, 11 do
        for _, value in ipairs(whiteKeysMultiples) do
            table.insert(self.whiteKeys, (i - 1) * 12 + value)
        end
    end
end

------------------ Events ------------------

function GUI.PitchEditor:init()
    self:calculateWhiteKeys()
    self:onresize()
    self:drawUI()
end
function GUI.PitchEditor:onupdate()
    --self:validateItems()
    self:drawUI()
    self:redraw()
end
function GUI.PitchEditor:onmousedown()
    self:redraw()
end
function GUI.PitchEditor:onmouseup()
    self:redraw()
end
function GUI.PitchEditor:ondrag()
    self:redraw()
end
function GUI.PitchEditor:onmousem_down()
    self.focus = true

    if GUI.IsInside(self) then
    end

    self:redraw()
end
function GUI.PitchEditor:onmousem_up()
    self:redraw()
end
function GUI.PitchEditor:onm_drag()
    self:redraw()
end
function GUI.PitchEditor:onmouser_down()
    self.focus = true

    if GUI.IsInside(self) then
    end

    self:redraw()
end
function GUI.PitchEditor:onmouser_up()
    self:redraw()
end
function GUI.PitchEditor:onr_drag()
    self:redraw()
end
function GUI.PitchEditor:onresize()
    self:redraw()
end
function GUI.PitchEditor:ondelete()
    GUI.FreeBuffer(self.uiBuffer)
end
function GUI.PitchEditor:ontype()
    local char = GUI.char
    if self.keys[char] then self.keys[char](self) end
    self:redraw()
end
function GUI.PitchEditor:onwheel(inc)
end

GUI.PitchEditor.keys = {
    [GUI.chars.DELETE] = function(self)
        --self:deleteSelectedCorrectionNodes()
    end,
    [GUI.chars.DOWN] = function(self)
        --self:moveSelectedNodesDown()
    end,
    [GUI.chars.UP] = function(self)
        --self:moveSelectedNodesUp()
    end,
    -- C -- Copy
    [3] = function(self)
        -- Holding control.
        --if gfx.mouse_cap & 4 == 4 then
        --    self:copySelectedCorrectionNodes()
        --end
    end,
    -- S -- Save
    [19] = function(self)
        -- Holding control.
        --if gfx.mouse_cap & 4 == 4 then
        --    self:savePitchCorrections()
        --end
    end,
    -- V -- Paste
    [22] = function(self)
        -- Holding control.
        --if gfx.mouse_cap & 4 == 4 then
        --    self:pasteNodes(true)
        --end
    end
}

------------------- Drawing -------------------

function GUI.PitchEditor:draw()
    gfx.blit(self.uiBuffer, 1, 0, 0, 0, self.w, self.h, self.x, self.y)
end
function GUI.PitchEditor:drawUI()
    self.uiBuffer = self.uiBuffer or GUI.GetBuffer()
    gfx.setimgdim(self.uiBuffer, -1, -1)
    gfx.setimgdim(self.uiBuffer, self.w, self.h)
    gfx.dest = self.uiBuffer
    self:drawKeyBackgrounds()
    --self:drawKeyLines()
    --self:drawItemEdges()
    --self:drawPitchLines()
    --self:drawPreviewPitchLines()
    --self:drawCorrectionGroup()
    --self:drawEditCursor()
    --self:drawBoxSelect()
end
function GUI.PitchEditor:drawKeyBackgrounds()
    local maxPitch = 128
    local blackKeyColor = {0.2, 0.2, 0.2, 1.0}
    local whiteKeyColor = {0.5, 0.5, 0.5, 1.0}
    local lastKeyEnd = self:getPixelsFromPitch(maxPitch + 0.5) - self.y
    for i = 1, maxPitch do
        Alk.setColor(blackKeyColor)
        for _, value in ipairs(self.whiteKeys) do
            if i == value then
                Alk.setColor(whiteKeyColor)
            end
        end
        local keyEnd = self:getPixelsFromPitch(maxPitch - i + 0.5) - self.y
        gfx.rect(0, keyEnd, self.w, keyEnd - lastKeyEnd + 1, 1)
        Alk.setColor(blackKeyColor)
        gfx.line(0, keyEnd, self.w, keyEnd, false)
        lastKeyEnd = keyEnd
    end
end
function GUI.PitchEditor:drawKeyLines()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local keyHeight = self.zoomY * h * 1.0 / self:getMaxPitch()

    if keyHeight > 16 then
        for i = 1, math.floor(self:getMaxPitch()) do
            GUI.color("key_lines")

            local keyLineHeight = self:getPixelsFromPitch(self:getMaxPitch() - i) - y

            gfx.line(0, keyLineHeight, w, keyLineHeight, false)

            gfx.a = 1.0
        end
    end
end
function GUI.PitchEditor:drawItemEdges()
    for index, group in ipairs(self.pitchGroups) do
        local leftBoundTime = group.editOffset
        local rightBoundTime = leftBoundTime + group.length

        local leftBoundPixels = self:getPixelsFromTime(leftBoundTime) - self.x
        local rightBoundPixels = self:getPixelsFromTime(rightBoundTime) - self.x

        local boxWidth = rightBoundPixels - leftBoundPixels
        local boxHeight = self.h - self.y - 1

        GUI.color("item_inside")

        gfx.rect(leftBoundPixels + 1, 2, boxWidth - 1, boxHeight - 1, 1)

        GUI.color("item_edges")

        gfx.rect(leftBoundPixels, 1, boxWidth, boxHeight, 0)
    end

    gfx.a = 1.0
end
function GUI.PitchEditor:drawEditCursor()
    local x, y, w, h = self.x, self.y, self.w, self.h

    local editCursorPosition = reaper.GetCursorPositionEx(0)
    local editCursorPixels = self:getPixelsFromTime(editCursorPosition - self:getTimeLeftBound()) - x

    local playPosition = reaper.GetPlayPositionEx(0)
    local playPositionPixels = self:getPixelsFromTime(playPosition - self:getTimeLeftBound()) - x

    GUI.color("edit_cursor")

    gfx.line(editCursorPixels, 0, editCursorPixels, h, false)

    local projectPlaystate = reaper.GetPlayStateEx(0)
    local projectIsPlaying = projectPlaystate & 1 == 1 or projectPlaystate & 4 == 4
    if projectIsPlaying then
        GUI.color("play_cursor")
        gfx.line(playPositionPixels, 0, playPositionPixels, h, false)
    end

    gfx.a = 1.0
end