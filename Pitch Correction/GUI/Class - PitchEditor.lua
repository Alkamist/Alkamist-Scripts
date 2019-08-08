if not GUI then
    reaper.ShowMessageBox("Couldn't access GUI functions.\n\nLokasenna_GUI - Core.lua must be loaded prior to any classes.", "Library Error", 0)
    missing_lib = true
    return 0
end

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

    self:redraw()
end

function GUI.PitchEditor:draw()
    local x, y, w, h = self.x, self.y, self.w, self.h

    -- Copy the pre-drawn bits
    gfx.blit(self.buff, 1, 0, 0, 0, self.orig_w, self.orig_h, x, y, w, h)

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

    self:redraw()
end

function GUI.PitchEditor:ondelete()
    GUI.FreeBuffer(self.buff)
end