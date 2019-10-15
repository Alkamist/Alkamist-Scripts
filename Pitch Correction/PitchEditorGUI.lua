package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end

local PitchEditor = require "Pitch Correction.PitchEditor"
local Alk = require "API.Alkamist API"

GUI.PitchEditor = GUI.Element:new()
function GUI.PitchEditor:new(name, z, x, y, w, h)
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

function GUI.PitchEditor:setWidth(width)
    self.w = width
    self.pitchEditor.pixelWidth = width
end
function GUI.PitchEditor:setHeight(height)
    self.h = height
    self.pitchEditor.pixelHeight = height
end

------------------ Events ------------------

function GUI.PitchEditor:init()
    self.pitchEditor = PitchEditor:new{
        --xPixelOffset = self.x,
        --yPixelOffset = self.y,
        pixelWidth = self.w,
        pixelHeight = self.h
    }
    self:onresize()
    self:drawUI()
end
function GUI.PitchEditor:onupdate()
    self.pitchEditor:updateSelectedItems()
    --self:drawUI()
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
    self:setWidth(GUI.cur_w or GUI.w - self.x)
    self:setHeight(GUI.cur_h or GUI.h - self.y)
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
function GUI.PitchEditor:draw()
    self:drawUI()
    --gfx.blit(self.uiBuffer, 1, 0, 0, 0, self.w, self.h, self.x, self.y)
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

function GUI.PitchEditor:drawUI()
    --self.uiBuffer = self.uiBuffer or GUI.GetBuffer()
    --gfx.setimgdim(self.uiBuffer, -1, -1)
    --gfx.setimgdim(self.uiBuffer, self.w, self.h)
    --gfx.dest = self.uiBuffer
    self.pitchEditor:draw()
end