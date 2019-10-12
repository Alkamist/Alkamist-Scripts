local AlkWrap = {}

-------------------- Media Items --------------------

function AlkWrap.getNumSelectedMediaItems(projectIndex)
    return reaper.CountSelectedMediaItems(projectIndex - 1)
end
function AlkWrap.getSelectedMediaItem(projectIndex, index)
    return reaper.GetSelectedMediaItem(projectIndex - 1, index - 1)
end
function AlkWrap.getSelectedMediaItems(projectIndex)
    local selectedItems = {}
    for index = 1, AlkWrap.getNumSelectedMediaItems(projectIndex) do
        table.insert(selectedItems, AlkWrap.getSelectedMediaItem(projectIndex, index))
    end
    return selectedItems
end
function AlkWrap.getItemLength(item)
    return reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
end
function AlkWrap.getItemLeftEdge(item)
    return reaper.GetMediaItemInfo_Value(item, "D_POSITION")
end
function AlkWrap.getItemRightEdge(item)
    return AlkWrap.getItemLeftEdge(item) + AlkWrap.getItemLength(item)
end
function AlkWrap.getItemLoops(item)
    return reaper.GetMediaItemInfo_Value(item, "B_LOOPSRC") > 0
end
function AlkWrap.getActiveTake(item)
    return reaper.GetActiveTake(item)
end
function AlkWrap.itemIsEmpty(item)
    return AlkWrap.getTakeType(AlkWrap.getActiveTake(item)) == nil
end
function AlkWrap.getItemName(item)
    if AlkWrap.itemIsEmpty(item) then
        return reaper.ULT_GetMediaItemNote(item)
    end
    return AlkWrap.getTakeName(AlkWrap.getActiveTake(item))
end


function AlkWrap.setItemLength(item, value)
    return reaper.SetMediaItemLength(item, value, false)
end
function AlkWrap.setItemLeftEdge(item, value)
    return reaper.SetMediaItemPosition(item, value, false)
end
function AlkWrap.setItemRightEdge(item, value)
    return AlkWrap.setItemLength(item, value - AlkWrap.getItemLeftEdge(item))
end
function AlkWrap.setItemLoops(item, value)
    return reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", value and 1 or 0)
end

-------------------- Media Takes --------------------

function AlkWrap.getTakeName(take)
    return reaper.GetTakeName(take)
end
function AlkWrap.getTakeType(take)
    if reaper.TakeIsMIDI(take) then
        return "midi"
    end
    return "audio"
end
function AlkWrap.getTakeGUID(take)
    return reaper.BR_GetMediaItemTakeGUID(take)
end
function AlkWrap.getTakeSource(take)
    return reaper.GetMediaItemTake_Source(take)
end
function AlkWrap.getTakePlayrate(take)
    return reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
end


function AlkWrap.setTakeName(take, value)
    reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", true)
end
function AlkWrap.setTakeSource(take, value)
    reaper.SetMediaItemTake_Source(take, value)
end
function AlkWrap.setTakeStartOffset(take, value)
    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", value)
end

-------------------- PCM Source --------------------

function AlkWrap.getSourceFileName(source)
    local url = reaper.GetMediaSourceFileName(source, "")
    return url:match("[^/\\]+$")
end
function AlkWrap.getSourceLength(source)
    local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(source)
    return sourceLength
end

return AlkWrap