-------------- Reaper Functions --------------

local Reaper = {}

function Reaper.msg(m)
    reaper.ShowConsoleMsg(tostring(m).."\n")
end

function Reaper.reaperCMD(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end

function Reaper.getEELCommandID(name)
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

    return nil
end

function Reaper.getItemType(item)
    local _, selectedChunk =  reaper.GetItemStateChunk(item, "", 0)
    local itemType = string.match(selectedChunk, "<SOURCE%s(%P%P%P).*\n")

    if itemType == nil then
        return "empty"
    elseif itemType == "MID" then
        return "midi"
    else
        return "audio"
    end
end

function Reaper.itemIsValid(item)
    local itemExists = reaper.ValidatePtr(item, "MediaItem*")
    return item ~= nil and itemExists
end

function Reaper.setItemSelected(item, selected)
    if Reaper.itemIsValid(item) then
        reaper.SetMediaItemSelected(item, selected)
    end
end

function Reaper.getSelectedItems()
    local outputItems = {}
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    for i = 1, numSelectedItems do
        local temporaryItem = reaper.GetSelectedMediaItem(0, i - 1)
        outputItems[i] = temporaryItem
    end
    return outputItems
end

function Reaper.restoreSelectedItems(items)
    if items ~= nil then
        Reaper.reaperCMD(40289) -- unselect all items
        for i = 1, #items do
            Reaper.setItemSelected(items[i], true)
        end
    end
end

function Reaper.getStretchMarkers(take)
    local stretchMarkers = {}
    local numStretchMarkers = reaper.GetTakeNumStretchMarkers(take)
    for i = 1, numStretchMarkers do
        local _, pos, srcPos = reaper.GetTakeStretchMarker(take, i - 1)

        stretchMarkers[i] = {
            pos = pos,
            srcPos = srcPos,
            slope = reaper.GetTakeStretchMarkerSlope(take, i - 1)
        }
    end

    for index, marker in ipairs(stretchMarkers) do
        local markerRate = 1.0
        local markerLength = 0
        if index < #stretchMarkers then
            local nextMarker = stretchMarkers[index + 1]

            markerLength = nextMarker.pos - marker.pos
            markerSourceLength = nextMarker.srcPos - marker.srcPos
            markerRate = markerSourceLength / markerLength * (1.0 - marker.slope)
        end

        marker.rate = markerRate
        marker.length = markerLength
        marker.srcLength = markerSourceLength
    end

    return stretchMarkers
end

function Reaper.getSourcePosition(take, time)
    if time == nil then return nil end

    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    local tempMarkerIndex = reaper.SetTakeStretchMarker(take, -1, time * playrate)

    local _, pos, srcPos = reaper.GetTakeStretchMarker(take, tempMarkerIndex)

    reaper.DeleteTakeStretchMarkers(take, tempMarkerIndex)

    return srcPos
end

function Reaper.getRealPosition(take, sourceTime)
    if sourceTime == nil then return nil end

    local startOffset = reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS")
    local playrate = reaper.GetMediaItemTakeInfo_Value(take, "D_PLAYRATE")

    local stretchMarkers = Reaper.getStretchMarkers(take)

    local markerIndex = 0

    for index, marker in ipairs(stretchMarkers) do
        if sourceTime < marker.srcPos then
            markerIndex = index - 1
            break
        end
    end

    if markerIndex == 0 then
        return ( sourceTime - reaper.GetMediaItemTakeInfo_Value(take, "D_STARTOFFS") ) / playrate
    end

    local activeMarker = stretchMarkers[markerIndex]

    local relativeSourcePosition = sourceTime - activeMarker.srcPos
    local effectiveMarkerRate =  activeMarker.rate + relativeSourcePosition * activeMarker.slope
    local scaledOffset = relativeSourcePosition / effectiveMarkerRate
    local realTime = activeMarker.pos + scaledOffset

    return realTime / playrate
end

local uiEnabled = true
function Reaper.setUIRefresh(enable)
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

return Reaper