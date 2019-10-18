local PointerWrapper = require "API.Reaper Wrappers.PointerWrapper"

local function Item(project, pointer)
    if project == nil then return nil end
    if pointer == nil then return nil end

    local item = PointerWrapper(pointer, "MediaItem*")

    -- Private Members:

    local _project = project

    -- Getters:

    function item:getProject()        return _project end
    function item:getTakeCount()      return reaper.CountTakes(self:getPointer()) end
    function item:getTake(takeNumber) return self:getProject():wrapTake(reaper.GetTake(self:getPointer(), takeNumber - 1)) end
    function item:getTakes()          return self:getProject():getIterator(self, self.getTake, self.getTakeCount) end
    function item:isSelected()        return reaper.IsMediaItemSelected(self:getPointer()) end
    function item:getLength()         return reaper.GetMediaItemInfo_Value(self:getPointer(), "D_LENGTH") end
    function item:getLeftEdge()       return reaper.GetMediaItemInfo_Value(self:getPointer(), "D_POSITION") end
    function item:getRightEdge()      return self:getLeftEdge() + self:getLength() end
    function item:getLoops()          return reaper.GetMediaItemInfo_Value(self:getPointer(), "B_LOOPSRC") > 0 end
    function item:getActiveTake()     return self:getProject():wrapTake(reaper.GetActiveTake(self:getPointer())) end
    function item:getTrack()          return self:getProject():wrapTrack(reaper.GetMediaItemTrack(self:getPointer())) end
    function item:isEmpty()           return self:getActiveTake():getType() == nil end
    function item:getName()
        if self:isEmpty() then
            return reaper.ULT_GetMediaItemNote(self:getPointer())
        end
        return self:getActiveTake():getName()
    end

    -- Setters:

    function item:setLoops(value)     reaper.SetMediaItemInfo_Value(self:getPointer(), "B_LOOPSRC", value and 1 or 0) end
    function item:setRightEdge(value) self:setLeftEdge(math.max(0.0, value - self:getLength())) end
    function item:setLeftEdge(value)  reaper.SetMediaItemPosition(self:getPointer(), value, false) end
    function item:setSelected(value)  reaper.SetMediaItemSelected(self:getPointer(), value) end
    function item:setLength(value)    reaper.SetMediaItemLength(self:getPointer(), value, false) end

    return item
end

return Item