local reaper = reaper

local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local Item = setmetatable({}, { __index = PointerWrapper })

function Item:new(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local base = PointerWrapper:new(pointer, "MediaItem*")
    local self = setmetatable(base, { __index = self })
    self.project = project

    return self
end

-- Getters:

function Item:getProject()        return self.project end
function Item:getTakeCount()      return reaper.CountTakes(self.pointer) end
function Item:getTake(takeNumber) return self:getProject():wrapTake(reaper.GetTake(self.pointer, takeNumber - 1)) end
function Item:getTakes()          return self:getIterator(self.getTake, self.getTakeCount) end
function Item:isSelected()        return reaper.IsMediaItemSelected(self.pointer) end
function Item:getLength()         return reaper.GetMediaItemInfo_Value(self.pointer, "D_LENGTH") end
function Item:getLeftEdge()       return reaper.GetMediaItemInfo_Value(self.pointer, "D_POSITION") end
function Item:getRightEdge()      return self:getLeftEdge() + self:getLength() end
function Item:getLoops()          return reaper.GetMediaItemInfo_Value(self.pointer, "B_LOOPSRC") > 0 end
function Item:getActiveTake()     return self:getProject():wrapTake(reaper.GetActiveTake(self.pointer)) end
function Item:getTrack()          return self:getProject():wrapTrack(reaper.GetMediaItemTrack(self.pointer)) end
function Item:isEmpty()           return self:getActiveTake():getType() == nil end
function Item:getName()
    if self:isEmpty() then
        return reaper.ULT_GetMediaItemNote(self.pointer)
    end
    return self:getActiveTake():getName()
end

-- Setters:

function Item:setLoops(value)     reaper.SetMediaItemInfo_Value(self.pointer, "B_LOOPSRC", value and 1 or 0) end
function Item:setRightEdge(value) self:setLeftEdge(math.max(0.0, value - self:getLength())) end
function Item:setLeftEdge(value)  reaper.SetMediaItemPosition(self.pointer, value, false) end
function Item:setSelected(value)  reaper.SetMediaItemSelected(self.pointer, value) end
function Item:setLength(value)    reaper.SetMediaItemLength(self.pointer, value, false) end

return Item