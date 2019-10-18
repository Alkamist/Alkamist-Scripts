local function Item(project, pointer)
    if pointer == nil then return nil end
    local item = {}

    -- Private Members:

    local _project = project
    local _pointer = pointer
    local _pointerType = "MediaItem*"

    -- Getters:

    function item:getPointer()        return _pointer end
    function item:getPointerType()    return _pointerType end
    function item:getProject()        return _project end
    function item:getTakeCount()      return reaper.CountTakes(_pointer) end
    function item:getTake(takeNumber) return _project:wrapTake(reaper.GetTake(_pointer, takeNumber - 1)) end
    function item:getTakes()          return _project:getIterator(self.getTake, self.getTakeCount) end
    function item:isSelected()        return reaper.IsMediaItemSelected(_pointer) end
    function item:getLength()         return reaper.GetMediaItemInfo_Value(_pointer, "D_LENGTH") end
    function item:getLeftEdge()       return reaper.GetMediaItemInfo_Value(_pointer, "D_POSITION") end
    function item:getRightEdge()      return self:getLeftEdge() + self:getLength() end
    function item:getLoops()          return reaper.GetMediaItemInfo_Value(_pointer, "B_LOOPSRC") > 0 end
    function item:getActiveTake()     return _project:wrapTake(reaper.GetActiveTake(_pointer)) end
    function item:getTrack()          return _project:wrapTrack(reaper.GetMediaItemTrack(_pointer)) end
    function item:isEmpty()           return self:getActiveTake():getType() == nil end
    function item:getName()
        if self:isEmpty() then
            return reaper.ULT_GetMediaItemNote(_pointer)
        end
        return self:getActiveTake():getName()
    end

    -- Setters:

    function item:setLoops(value)     reaper.SetMediaItemInfo_Value(_pointer, "B_LOOPSRC", value and 1 or 0) end
    function item:setRightEdge(value) self:setLeftEdge(math.max(0.0, value - self:getLength())) end
    function item:setLeftEdge(value)  reaper.SetMediaItemPosition(_pointer, value, false) end
    function item:setSelected(value)  reaper.SetMediaItemSelected(_pointer, value) end
    function item:setLength(value)    reaper.SetMediaItemLength(_pointer, value, false) end

    return item
end

return Item