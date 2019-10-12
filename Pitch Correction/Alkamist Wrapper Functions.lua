local AlkWrap = {}

-------------------- General Functions --------------------

function AlkWrap.mainCommand(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
        return
    end
    reaper.Main_OnCommand(id, 0)
end
function AlkWrap.getEELCommandID(name)
    local kbini = reaper.GetResourcePath() .. '/reaper-kb.ini'
    local file = io.open(kbini, 'r')

    local content = nil
    if file then
        content = file:read('a')
        file:close()
    end

    if content then
        local nameString = nil
        for line in content:gmatch('[^\r\n]+') do
            if line:match(name) then
                nameString = line:match('SCR %d+ %d+ ([%a%_%d]+)')
                break
            end
        end

        local commandID = nil
        if nameString then
            commandID = reaper.NamedCommandLookup('_' .. nameString)
        end

        if commandID and commandID ~= 0 then
            return commandID
        end
    end

    reaper.MB(name .. " not found!", "Error!", 0)
    return nil
end
local uiEnabled = true
function AlkWrap.setUIRefresh(enable)
    -- Enable UI refresh.
    if enable then
        if not uiEnabled then
            reaper.PreventUIRefresh(-1)
            uiEnabled = true
        end

    -- Disable UI refresh.
    else
        if uiEnabled then
            reaper.PreventUIRefresh(1)
            uiEnabled = false
        end
    end
end
function AlkWrap.updateArrange()
    reaper.UpdateArrange()
end

-------------------- MediaTrack* --------------------

-- Getters.
function AlkWrap.getTrackNumber(track)
    return reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
end

-- Setters.

-------------------- MediaItem* --------------------

-- Getters.
function AlkWrap.getNumSelectedItems(projectIndex)
    return reaper.CountSelectedMediaItems(projectIndex - 1)
end
function AlkWrap.getSelectedItem(projectIndex, index)
    return reaper.GetSelectedMediaItem(projectIndex - 1, index - 1)
end
function AlkWrap.getSelectedItems(projectIndex)
    local selectedItems = {}
    for index = 1, AlkWrap.getNumSelectedItems(projectIndex) do
        table.insert(selectedItems, AlkWrap.getSelectedItem(projectIndex, index))
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
function AlkWrap.getItemActiveTake(item)
    return reaper.GetActiveTake(item)
end
function AlkWrap.itemIsEmpty(item)
    return AlkWrap.getTakeType(AlkWrap.getItemActiveTake(item)) == nil
end
function AlkWrap.getItemName(item)
    if AlkWrap.itemIsEmpty(item) then
        return reaper.ULT_GetMediaItemNote(item)
    end
    return AlkWrap.getTakeName(AlkWrap.getItemActiveTake(item))
end
function AlkWrap.getItemTrack(item)
    return reaper.GetMediaItemTrack(item)
end

-- Setters.
function AlkWrap.setItemLength(item, value)
    return reaper.SetMediaItemLength(item, value, false)
end
function AlkWrap.setItemLeftEdge(item, value)
    return reaper.SetMediaItemPosition(item, value, false)
end
function AlkWrap.setItemRightEdge(item, value)
    return AlkWrap.setItemLeftEdge(item, math.max(0.0, value - AlkWrap.getItemLength(item)))
end
function AlkWrap.setItemLoops(item, value)
    return reaper.SetMediaItemInfo_Value(item, "B_LOOPSRC", value and 1 or 0)
end

-------------------- MediaItem_Take* --------------------

-- Getters.
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
function AlkWrap.getTakeItem(take)
    return reaper.GetMediaItemTake_Item(take)
end
function AlkWrap.getTakeSource(take)
    return reaper.GetMediaItemTake_Source(take)
end
function AlkWrap.getTakePlayrate(take)
    return reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")
end
function AlkWrap.getTakePitchEnvelope(take)
    return reaper.GetTakeEnvelopeByName(take, "Pitch")
end
function AlkWrap.createAndGetTakePitchEnvelope(take)
    local pitchEnvelope = AlkWrap.getTakePitchEnvelope(take)
    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        AlkWrap.mainCommand("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
        pitchEnvelope = AlkWrap.getTakePitchEnvelope(take)
    end
    AlkWrap.mainCommand("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope
    return pitchEnvelope
end
function AlkWrap.getTakeSourceTime(take, realTime)
    if time == nil then return nil end
    local tempMarkerIndex = reaper.SetTakeStretchMarker(take, -1, realTime * AlkWrap.getTakePlayrate(take))
    local _, _, sourcePosition = reaper.GetTakeStretchMarker(take, tempMarkerIndex)
    reaper.DeleteTakeStretchMarkers(take, tempMarkerIndex)
    return sourcePosition
end
function AlkWrap.getTakeStartOffset(take)
    return AlkWrap.getTakeSourceTime(take, 0.0)
end
function AlkWrap.getTakeStretchMarkers(take)
    local stretchMarkers = {}
    local numStretchMarkers = reaper.GetTakeNumStretchMarkers(take)
    for i = 1, numStretchMarkers do
        local _, time, sourceTime = reaper.GetTakeStretchMarker(take, i - 1)

        stretchMarkers[i] = {
            time = time,
            sourceTime = sourceTime,
            slope = reaper.GetTakeStretchMarkerSlope(take, i - 1),
            rate = 1.0,
            length = 0.0,
            sourceLength = 0.0
        }
    end

    for index, marker in ipairs(stretchMarkers) do
        local markerRate = 1.0
        local markerLength = 0.0
        if index < #stretchMarkers then
            local nextMarker = stretchMarkers[index + 1]

            markerLength = nextMarker.time - marker.time
            markerSourceLength = nextMarker.sourceTime - marker.sourceTime
            markerRate = markerSourceLength / markerLength * (1.0 - marker.slope)
        else
            markerLength = 0.0
            markerSourceLength = 0.0
            markerRate = 1.0
        end

        marker.rate = markerRate
        marker.length = markerLength
        marker.sourceLength = markerSourceLength
    end

    return stretchMarkers
end
function AlkWrap.getTakeRealTime(take, sourceTime)
    if sourceTime == nil then return nil end

    local stretchMarkers = AlkWrap.getTakeStretchMarkers(take)
    local startOffset = AlkWrap.getTakeStartOffset(take)
    local playrate = AlkWrap.getTakePlayrate(take)
    local numStretchMarkers = #stretchMarkers

    if numStretchMarkers < 1 then
        return (sourceTime - startOffset) / playrate
    end

    local markerIndex = 0

    for index, marker in ipairs(stretchMarkers) do
        if sourceTime < marker.sourceTime then
            markerIndex = index - 1
            break
        end

        if index == numStretchMarkers then
            markerIndex = index
        end
    end

    if markerIndex == 0 then
        return (sourceTime - startOffset) / playrate
    end

    local activeMarker = stretchMarkers[markerIndex]

    local relativeSourcePosition = sourceTime - activeMarker.sourceTime

    local actualSlope = 0.0
    if activeMarker.sourceLength > 0 and activeMarker.length > 0 then
        actualSlope = (activeMarker.sourceLength / activeMarker.length - activeMarker.rate) / (0.5 * activeMarker.sourceLength)
    end

    local currentMarkerRate = activeMarker.rate + relativeSourcePosition * actualSlope
    local averageMarkerRate = (activeMarker.rate + currentMarkerRate) * 0.5
    local scaledOffset = relativeSourcePosition / averageMarkerRate

    local realTime = activeMarker.time + scaledOffset

    return realTime / playrate
end

-- Setters.
function AlkWrap.setTakeName(take, value)
    reaper.GetSetMediaItemTakeInfo_String(take, "P_NAME", "", true)
end
function AlkWrap.setTakeSource(take, value)
    reaper.SetMediaItemTake_Source(take, value)
end
function AlkWrap.setTakeStartOffset(take, value)
    reaper.SetMediaItemTakeInfo_Value(take, "D_STARTOFFS", value)
end

-------------------- PCM_Source* --------------------

-- Getters.
function AlkWrap.getSourceFileName(source)
    local url = reaper.GetMediaSourceFileName(source, "")
    return url:match("[^/\\]+$")
end
function AlkWrap.getSourceLength(source)
    local _, _, sourceLength = reaper.PCM_Source_GetSectionInfo(source)
    return sourceLength
end

return AlkWrap