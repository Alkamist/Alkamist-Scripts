-- @description Region Item Functions
-- @version 1.0
-- @author Alkamist
-- @donate https://paypal.me/CoreyLehmanMusic
-- @about
--   This file contains various functions that are used by the region item actions.
--   The other region item scripts won't run without it.

function msg(message)
  reaper.ShowConsoleMsg(tostring(message).."\n")
end

function reaperCMD(id)
    if type(id) == "string" then
        reaper.Main_OnCommand(reaper.NamedCommandLookup(id), 0)
    else
        reaper.Main_OnCommand(id, 0)
    end
end

function timeToBeats(time)
    local beatsSinceMeasure, measure, numerator, fullBeats, denominator = reaper.TimeMap2_timeToBeats(0, time)
    return fullBeats
end

function beatsToTime(beats)
    return reaper.TimeMap2_beatsToTime(0, beats)
end

function getRegionLeftBound(region)
    local output = nil

    if itemIsValid(region) then
        output = reaper.GetMediaItemInfo_Value(region, "D_POSITION")
    end

    return output
end

function getRegionRightBound(region)
    local output = nil

    if itemIsValid(region) then
        output = reaper.GetMediaItemInfo_Value(region, "D_POSITION") + reaper.GetMediaItemInfo_Value(region, "D_LENGTH")
    end

    return output
end

function getRegionStart(region)
    local output = nil

    if itemIsValid(region) then
        output = reaper.GetMediaItemInfo_Value(region, "D_POSITION") + getItemSourceOffset(region) / getRegionPlayrate(region)
    end

    return output
end

function getRegionEffectiveStart(region)
    local output = nil

    if itemIsValid(region) then
        output = math.max(getRegionStart(region), getRegionLeftBound(region))
    end

    return output
end

function getRegionLength(region)
    local output = nil

    if itemIsValid(region) then
        output = getRegionRightBound(region) - getRegionEffectiveStart(region)
    end

    return output
end

function getRegionStartOffset(region)
    local output = nil

    if itemIsValid(region) then
        output = getRegionStart(region) - getRegionLeftBound(region)
    end

    return output
end

function getRegionFadeIn(region)
    local output = nil

    if itemIsValid(region) then
        output = reaper.GetMediaItemInfo_Value(region, "D_FADEINLEN")
    end

    return output
end

function getRegionFadeOut(region)
    local output = nil

    if itemIsValid(region) then
        output = reaper.GetMediaItemInfo_Value(region, "D_FADEOUTLEN")
    end

    return output
end

function getRegionPitch(region)
    local output = nil

    if itemIsValid(region) then
        output = reaper.GetMediaItemTakeInfo_Value(getItemActiveTake(region), "D_PITCH")
    end

    return output
end

function getRegionPlayrate(region)
    local output = nil

    if itemIsValid(region) then
        output = reaper.GetMediaItemTakeInfo_Value(getItemActiveTake(region), "D_PLAYRATE")
    end

    return output
end

function getItemSnapOffset(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
    end

    return output
end

function getItemPosition(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_SNAPOFFSET")
    end

    return output
end

function getItemLength(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    end

    return output
end

function getItemLengthBeats(item)
    local output = nil

    if itemIsValid(item) then
        output = timeToBeats(getItemLeftBound(item) + getItemLength(item)) - timeToBeats(getItemLeftBound(item))
    end

    return output
end

function getItemLeftBound(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemInfo_Value(item, "D_POSITION")
    end

    return output
end

function getItemRightBound(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemInfo_Value(item, "D_POSITION") + reaper.GetMediaItemInfo_Value(item, "D_LENGTH")
    end

    return output
end

function getItemFadeIn(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN")
    end

    return output
end

function getItemFadeInBeats(item)
    local itemFadeInTime = getItemFadeIn(item)

    if itemFadeInTime ~= nil then
        local itemLeftBound = getItemLeftBound(item)
        return timeToBeats(itemFadeInTime + itemLeftBound) - timeToBeats(itemLeftBound)
    else
        return nil
    end
end

function getItemFadeOut(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN")
    end

    return output
end

function getItemFadeOutBeats(item)
    local itemFadeOutTime = getItemFadeOut(item)

    if itemFadeOutTime ~= nil then
        local itemRightBound = getItemRightBound(item)
        return timeToBeats(itemRightBound) - timeToBeats(itemRightBound - itemFadeOutTime)
    else
        return nil
    end
end

function getItemAutoFadeIn(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemInfo_Value(item, "D_FADEINLEN_AUTO")
    end

    return output
end

function getItemAutoFadeInBeats(item)
    local itemFadeInTime = getItemAutoFadeIn(item)

    if itemFadeInTime ~= nil then
        local itemLeftBound = getItemLeftBound(item)
        return timeToBeats(itemFadeInTime + itemLeftBound) - timeToBeats(itemLeftBound)
    else
        return nil
    end
end

function getItemAutoFadeOut(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemInfo_Value(item, "D_FADEOUTLEN_AUTO")
    end

    return output
end

function getItemAutoFadeOutBeats(item)
    local itemFadeOutTime = getItemAutoFadeOut(item)

    if itemFadeOutTime ~= nil then
        local itemRightBound = getItemRightBound(item)
        return timeToBeats(itemRightBound) - timeToBeats(itemRightBound - itemFadeOutTime)
    else
        return nil
    end
end

function itemIsValid(item)
    local itemExists = reaper.ValidatePtr(item, "MediaItem*")
    return item ~= nil and itemExists
end

function trackIsValid(track)
    local trackExists = reaper.ValidatePtr(track, "MediaTrack*")
    return track ~= nil and trackExists
end

function restoreSelectedItems(items)
    if items ~= nil then
        reaperCMD(40289) -- unselect all items
        for i = 1, #items do
            setItemSelected(items[i], true)
        end
    end
end

function restoreSelectedTracks(tracks)
    if tracks ~= nil then
        reaperCMD(40297) -- unselect all tracks
        for i = 1, #tracks do
            setTrackSelected(tracks[i], true)
        end
    end
end

function getSelectedTracks()
    local outputTracks = {}
    local numTracks = reaper.CountSelectedTracks(0)
    for i = 1, numTracks do
        local temporaryTrack = reaper.GetSelectedTrack(0, i - 1)
        outputTracks[i] = temporaryTrack
    end
    return outputTracks
end

function getSelectedItems()
    local outputItems = {}
    local numSelectedItems = reaper.CountSelectedMediaItems(0)
    for i = 1, numSelectedItems do
        local temporaryItem = reaper.GetSelectedMediaItem(0, i - 1)
        outputItems[i] = temporaryItem
    end
    return outputItems
end

function getSelectedMIDIItems()
    local outputSelectedItems = {}
    local countItems = reaper.CountSelectedMediaItems(0)

    local i = 1
    local j = 1
    for i = 1, countItems do
        local currentItem = reaper.GetSelectedMediaItem(0, i - 1)

        if getItemType(currentItem) == "midi" then
            outputSelectedItems[j] = currentItem
            j = j + 1
        end
    end

    return outputSelectedItems
end

function setItemSelected(item, selected)
    if itemIsValid(item) then
        reaper.SetMediaItemSelected(item, selected)
    end
end

function setTrackSelected(track, selected)
    if trackIsValid(track) then
        reaper.SetTrackSelected(track, selected)
    end
end

function getTrackNumber(track)
    local output = nil

    if trackIsValid(track) then
        output = reaper.GetMediaTrackInfo_Value(track, "IP_TRACKNUMBER")
    end

    return output
end

function getItemTrack(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItem_Track(item)
    end

    return output
end

function getItemBeatAttachMode(item)
    local output = nil

    if itemIsValid(item) then
        local itemSetting = reaper.GetMediaItemInfo_Value(item, "C_BEATATTACHMODE")
        local trackSetting = reaper.GetMediaTrackInfo_Value(getItemTrack(item), "C_BEATATTACHMODE")

        if itemSetting == -1 and trackSetting ~= -1 then
            output = trackSetting
        elseif itemSetting == -1 and trackSetting == -1 then
            output = 1
        else
            output = itemSetting
        end
    end

    if output == 0 then
        return "time"
    elseif output == 1 then
        return "all_beats"
    elseif output == 2 then
        return "beats_pos_only"
    else
        return nil
    end
end

function getTrackBeatAttachMode(track)
    local output = nil

    if trackIsValid(track) then
        local trackSetting = reaper.GetMediaTrackInfo_Value(track, "C_BEATATTACHMODE")

        if trackSetting == -1 then
            output = 1
        else
            output = trackSetting
        end
    end

    if output == 0 then
        return "time"
    elseif output == 1 then
        return "all_beats"
    elseif output == 2 then
        return "beats_pos_only"
    else
        return nil
    end
end

function getItemTrackNumber(item)
    local output = nil

    if itemIsValid(item) then
        output = getTrackNumber(getItemTrack(item))
    end

    return output
end

function getItemTake(item, takeNumber)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemTake(item, takeNumber)
    end

    return output
end

function getItemActiveTake(item)
    local output = nil

    if itemIsValid(item) then
        output = getItemTake(item, reaper.GetMediaItemInfo_Value(item, "I_CURTAKE"))
    end

    return output
end

function isTrackIgnored(track)
    local trackIsIgnored = false
    local _, trackName = reaper.GetSetMediaTrackInfo_String(track, "P_NAME", "", false);

    local firstChar = string.sub(trackName, 1, 1)
    if firstChar == "*" then
        trackIsIgnored = true
    end

    return trackIsIgnored
end

function selectOnlyIgnoredTracks(tracks)
    reaperCMD(40297) -- unselect all tracks

    for i = 1, #tracks do
        if isTrackIgnored(tracks[i]) then
            setTrackSelected(tracks[i], true)
        end
    end
end

function selectIgnoredChildTracks(inputRegion)
    local parentTrack = reaper.GetMediaItem_Track(inputRegion)
    setOnlyTrackSelected(parentTrack)
    reaperCMD("_SWS_SELCHILDREN")
    local selectedTracks = getSelectedTracks()
    selectOnlyIgnoredTracks(selectedTracks)
end

function setOnlyTrackSelected(track)
    if trackIsValid(track) then
        reaper.SetOnlyTrackSelected(track)
    end
end

function unselectIgnoredTracks()
    local selectedTracks = getSelectedTracks()

    for i = 1, #selectedTracks do
        local _, selectedTrackName = reaper.GetSetMediaTrackInfo_String(selectedTracks[i], "P_NAME", "", false);

        local firstChar = string.sub(selectedTrackName, 1, 1)
        if firstChar == "*" then
            setTrackSelected(selectedTracks[i], false)
        end
    end
end

function getItemSourceOffset(item)
    local output = nil

    if itemIsValid(item) then
        output = reaper.GetMediaItemTakeInfo_Value(getItemActiveTake(item), "D_STARTOFFS")
    end

    return -output
end

function getItemType(item)
    local _, selectedChunk =  reaper.GetItemStateChunk(item, "", 0)
    local  itemType = string.match(selectedChunk, "<SOURCE%s(%P%P%P).*\n")
    if itemType == nil then
        return "empty"
    elseif itemType == "MID" then
        return "midi"
    else
        return "audio"
    end
end

function getRegionName(item)
    if getItemType(item) == "empty" then
        return reaper.ULT_GetMediaItemNote(item)
    else
        local take = reaper.GetActiveTake(item)
        local takeName = reaper.GetTakeName(take)
        return takeName
    end
end

function unselectItemsThatAreNotOnSelectedTracks()
    local selectedTracks = getSelectedTracks()
    local selectedItems = getSelectedItems()

    for i = 1, #selectedItems do
        local itemTrackNumber = getItemTrackNumber(selectedItems[i])

        for j = 1, #selectedTracks do
            local currentTrackNumber = getTrackNumber(selectedTracks[j])

            if itemTrackNumber ~= currentTrackNumber then
                setItemSelected(selectedItems[i], false)
            end
        end
    end
end

function getRegionItems(inputRegion)
    local parentTrack = reaper.GetMediaItem_Track(inputRegion)
    setOnlyTrackSelected(parentTrack)

    reaperCMD(41611) -- select all pooled items
    setItemSelected(inputRegion, false)
    unselectItemsThatAreNotOnSelectedTracks()

    local outputRegionItems = {}
    local countItems = reaper.CountSelectedMediaItems(0)

    local i = 1
    local j = 1
    for i = 1, countItems do
        local currentItem = reaper.GetSelectedMediaItem(0, i - 1)
        local itemTrack = reaper.GetMediaItem_Track(currentItem)

        if getItemType(currentItem) ~= "empty" and not isTrackIgnored(itemTrack) then
            outputRegionItems[j] = currentItem
            j = j + 1
        end
    end

    return outputRegionItems
end

function unselectItemsThatStartOutsideOfRegion(inputRegion)
    local selectedChildren = getSelectedItems()

    for i = 1, #selectedChildren do
        if not itemIsWithinRegion(inputRegion, selectedChildren[i]) then
            setItemSelected(selectedChildren[i], false)
        end
    end
end

function itemIsWithinRegion(inputRegion, item)
    -- A little tolerance needs to be added for selecting items on the
    -- edge cases of regions since reaper is finicky about it.
    local positionTolerance = 0.0001

    return timeIsWithinRegion(inputRegion, getItemPosition(item) + positionTolerance)
end

function timeIsWithinRegion(inputRegion, time)
    return time >= getRegionEffectiveStart(inputRegion) and time < getRegionRightBound(inputRegion)
end

function getTrackFolderDepth(track)
    local previouslySelectedTracks = getSelectedTracks()
    setOnlyTrackSelected(track)
    local folderDepth = 0

    while reaper.GetSelectedTrack(0, 0) ~= nil do
        reaperCMD("_SWS_SELPARENTS")
        folderDepth = folderDepth + 1
    end

    restoreSelectedTracks(previouslySelectedTracks)
    return folderDepth
end

local sourceEnvelopes = {}
function populateSourceEnvelopes(inputRegion)
    selectChildTracks(inputRegion)
    local sourceTracks = getSelectedTracks()

    for i = 1, #sourceTracks do
        sourceEnvelopes[i] = {}

        for j = 1, reaper.CountTrackEnvelopes(sourceTracks[i]) do
            sourceEnvelopes[i][j] = reaper.GetTrackEnvelope(sourceTracks[i], j - 1)
        end
    end
end

-- We need to insert edge points into the source automation items so
-- we don't lose the edge points during certain edge cases while transferring.
function insertEdgePointsInAutomationItem(envelope, aiIndex)
    local edgePointInwardSpacing = 0.0001

    local numPointsInSourceItem = reaper.CountEnvelopePointsEx(envelope, aiIndex)
    local retval, leftPointTime, leftPointValue, leftPointShape, leftPointTension, leftPointSelected = reaper.GetEnvelopePointEx(envelope, aiIndex, 0)
    local retval, leftPoint2Time, leftPoint2Value, leftPoint2Shape, leftPoint2Tension, leftPoint2Selected = reaper.GetEnvelopePointEx(envelope, aiIndex, 1)
    local retval2, rightPointTime, rightPointValue, rightPointShape, rightPointTension, rightPointSelected = reaper.GetEnvelopePointEx(envelope, aiIndex, numPointsInSourceItem - 1)
    local retval2, rightPoint2Time, rightPoint2Value, rightPoint2Shape, rightPoint2Tension, rightPoint2Selected = reaper.GetEnvelopePointEx(envelope, aiIndex, numPointsInSourceItem - 2)

    local leftEdgeTime = leftPointTime + edgePointInwardSpacing
    local rightEdgeTime = rightPointTime - edgePointInwardSpacing

    -- Only insert the edge points if there aren't already points there.
    if leftEdgeTime < leftPoint2Time then
        reaper.InsertEnvelopePointEx(envelope, aiIndex, leftEdgeTime, leftPointValue, leftPointShape, leftPointTension, false, false)
    end

    if rightEdgeTime > rightPoint2Time then
        reaper.InsertEnvelopePointEx(envelope, aiIndex, rightEdgeTime, rightPointValue, rightPointShape, rightPointTension, false, false)
    end
end

local sourceTransferItems = {}
function insertTransferItems(inputSourceRegion, inputDestinationRegion)
    reaperCMD(40769) -- unselect all tracks/items/envelope points

    selectChildTracks(inputSourceRegion)
    local sourceTracks = getSelectedTracks()
    selectChildTracks(inputDestinationRegion)
    local selectedTracks = getSelectedTracks()

    local isSourceRegion = inputDestinationRegion == inputSourceRegion

    local sourcePlayrate = getRegionPlayrate(inputSourceRegion)
    local regionPlayrate = getRegionPlayrate(inputDestinationRegion)

    for i = 1, #sourceTracks do
        if isSourceRegion then
            sourceTransferItems[i] = {}
        end

        local beatAttachMode = getTrackBeatAttachMode(sourceTracks[i])
        for j = 1, reaper.CountTrackEnvelopes(selectedTracks[i]) do
            reaperCMD(40769) -- unselect all tracks/items/envelope points

            currentEnvelope = reaper.GetTrackEnvelope(selectedTracks[i], j - 1)

            local itemStart = getRegionEffectiveStart(inputDestinationRegion)
            local itemLength = getRegionRightBound(inputDestinationRegion) - itemStart

            if isSourceRegion then
                sourceTransferItems[i][j] = {}
                sourceTransferItems[i][j].orderID = reaper.InsertAutomationItem(sourceEnvelopes[i][j], -1, itemStart, itemLength)
                sourceTransferItems[i][j].poolID = reaper.GetSetAutomationItemInfo(sourceEnvelopes[i][j], sourceTransferItems[i][j].orderID, "D_POOL_ID", 0, false)
                reaper.GetSetAutomationItemInfo(sourceEnvelopes[i][j], sourceTransferItems[i][j].orderID, "D_LOOPSRC", 0, true)

                insertEdgePointsInAutomationItem(sourceEnvelopes[i][j], sourceTransferItems[i][j].orderID)
            else
                if sourceTransferItems[i][j].poolID ~= nil then
                    local newTransferItemIndex = reaper.InsertAutomationItem(currentEnvelope, sourceTransferItems[i][j].poolID, itemStart, itemLength)

                    local newPlayrate = regionPlayrate / sourcePlayrate
                    reaper.GetSetAutomationItemInfo(currentEnvelope, newTransferItemIndex, "D_PLAYRATE", newPlayrate, true)

                    local sourceStartOffset = getRegionEffectiveStart(inputSourceRegion) - getRegionStart(inputSourceRegion)
                    local destinationStartOffset = getRegionEffectiveStart(inputDestinationRegion) - getRegionStart(inputDestinationRegion)
                    local itemStartOffsetTime = sourceStartOffset - destinationStartOffset * newPlayrate

                    if beatAttachMode ~= "time" then
                        local sourceStartOffsetBeats = (timeToBeats(getRegionEffectiveStart(inputSourceRegion)) - timeToBeats(getRegionStart(inputSourceRegion))) * sourcePlayrate
                        local destinationStartOffsetBeats = (timeToBeats(getRegionEffectiveStart(inputDestinationRegion)) - timeToBeats(getRegionStart(inputDestinationRegion))) * regionPlayrate
                        local itemStartOffsetBeats = (sourceStartOffsetBeats - destinationStartOffsetBeats) / regionPlayrate
                        itemStartOffsetTime = (beatsToTime(timeToBeats(getRegionEffectiveStart(inputDestinationRegion)) + itemStartOffsetBeats) - getRegionEffectiveStart(inputDestinationRegion)) * newPlayrate
                    end

                    reaper.GetSetAutomationItemInfo(currentEnvelope, newTransferItemIndex, "D_LOOPSRC", 0, true)
                    reaper.GetSetAutomationItemInfo(currentEnvelope, newTransferItemIndex, "D_UISEL", 1, true)
                    reaper.GetSetAutomationItemInfo(currentEnvelope, newTransferItemIndex, "D_STARTOFFS", -itemStartOffsetTime, true)

                    reaperCMD(42088) -- delete automation items preserving points
                end
            end
        end
    end

    reaperCMD(40769) -- unselect all tracks/items/envelope points
end

function getFXAndParamIndexFromEnv(envelope)
    local track = reaper.Envelope_GetParentTrack(envelope)
    local numFX = reaper.TrackFX_GetCount(track)
    for j = 1, numFX do
        local numFXParameters = reaper.TrackFX_GetNumParams(track, j - 1)
        for k = 1, numFXParameters do
            if reaper.GetFXEnvelope(track, j - 1, k - 1, false) == envelope then
                return j - 1, k - 1 -- returns fxIndex and fxParamIndex.
            end
        end
    end
end

-- This function essentially checks if you put a region on a different set of tracks
-- and will copy the source child tracks and paste them as children under the
-- destination region. This is currently disabled since I added functionality to
-- include tracks as children by naming them with the region item's name as a tag.
local alreadyPreparedTrack = {}
function prepareDestinationForTransfer(inputSourceRegion, inputDestinationRegion)
    reaperCMD(40769) -- unselect all tracks/items/envelope points

    local garbageTracks = {}

    local sourceTrack = reaper.GetMediaItem_Track(inputSourceRegion)
    local sourceTrackNumber = reaper.GetMediaTrackInfo_Value(sourceTrack, "IP_TRACKNUMBER")
    local destinationTrack = reaper.GetMediaItem_Track(inputDestinationRegion)
    local destinationTrackNumber = reaper.GetMediaTrackInfo_Value(destinationTrack, "IP_TRACKNUMBER")
    local destinationIsOnDifferentTracks = sourceTrackNumber ~= destinationTrackNumber

    if destinationIsOnDifferentTracks then
        if alreadyPreparedTrack[destinationTrackNumber] == nil or alreadyPreparedTrack[destinationTrackNumber] == false then
            selectIgnoredChildTracks(inputDestinationRegion)
            local destinationHasIgnoredTracks = reaper.CountSelectedTracks(0) > 0

            selectChildTracks(inputDestinationRegion)
            reaperCMD(40005) -- remove tracks

            -- Copy the source tracks.
            selectAllChildTracksIncludingIgnored(inputSourceRegion)
            reaperCMD(40210) -- copy tracks

            -- Paste the source tracks at the destination.
            setOnlyTrackSelected(destinationTrack)
            reaperCMD(40058) -- paste items/tracks

            local pastedTracks = getSelectedTracks()

            -- My hackey way to get the pasted tracks to be in the proper folder
            -- if there aren't ignore tracks there already to anchor them.
            local destinationFolderDepth = getTrackFolderDepth(destinationTrack)
            if destinationFolderDepth > 0 and not destinationHasIgnoredTracks then
                setTrackSelected(destinationTrack, true)
                for i = 1, destinationFolderDepth + 1 do
                    reaperCMD("_SWS_MAKEFOLDER")
                end
                setTrackSelected(destinationTrack, false)
            end

            -- Clean up the leftover media items.
            reaperCMD(40421) -- select all items on track
            reaperCMD(40006) -- remove items

            for i = 1, #pastedTracks do
                -- Clean up the automation that was created from the source region.
                for j = 1, reaper.CountTrackEnvelopes(pastedTracks[i]) do
                    reaperCMD(40769) -- unselect all tracks/items/envelope points
                    local currentEnvelope = reaper.GetTrackEnvelope(pastedTracks[i], j - 1)

                    for k = 1, reaper.CountAutomationItems(currentEnvelope) do
                        reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_UISEL", 1, true)
                    end

                    reaperCMD(42086) -- delete automation items

                    local _, lastEnvelopeTime = reaper.GetEnvelopePoint(currentEnvelope, reaper.CountEnvelopePoints(currentEnvelope) - 1)
                    reaper.DeleteEnvelopePointRange(currentEnvelope, 0, lastEnvelopeTime)
                end
            end

            -- Document the garbage tracks that need to be cleaned up later.
            selectOnlyIgnoredTracks(pastedTracks)
            garbageTracks = getSelectedTracks()

            alreadyPreparedTrack[destinationTrackNumber] = true
        end
    end

    reaperCMD(40769) -- unselect all tracks/items/envelope points

    return garbageTracks
end

function removeSourceTransferItems(inputRegion)
    reaperCMD(40769) -- unselect all tracks/items/envelope points

    selectChildTracks(inputRegion)
    local selectedTracks = getSelectedTracks()
    for i = 1, #selectedTracks do
        for j = 1, #sourceEnvelopes[i] do
            reaperCMD(40769) -- unselect all tracks/items/envelope points

            currentEnvelope = reaper.GetTrackEnvelope(selectedTracks[i], j - 1)

            reaper.GetSetAutomationItemInfo(currentEnvelope, sourceTransferItems[i][j].orderID, "D_UISEL", 1, true)
            reaperCMD(42088) -- delete automation items preserving points
        end
    end

    reaperCMD(40769) -- unselect all tracks/items/envelope points
end

local sourceAIs = {}
function copySourceAutomationItems(sourceRegion)
    reaperCMD(40769) -- unselect all tracks/items/envelope points

    local regionPlayrate = getRegionPlayrate(sourceRegion)
    local regionStartBeats = timeToBeats(getRegionStart(sourceRegion))

    selectChildTracks(sourceRegion)
    local selectedTracks = getSelectedTracks()
    for i = 1, #selectedTracks do
        sourceAIs[i] = {}
        for j = 1, #sourceEnvelopes[i] do
            sourceAIs[i][j] = {}
            currentEnvelope = reaper.GetTrackEnvelope(selectedTracks[i], j - 1)

            local AIIndex = 1
            for k = 1, reaper.CountAutomationItems(currentEnvelope) do
                local AIPosition = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_POSITION", 0, false)

                -- Loop through and record information about all automation items that are within
                -- the source region.
                if timeIsWithinRegion(sourceRegion, AIPosition) then
                    sourceAIs[i][j][AIIndex] = {}
                    local sourceAIPosition = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_POSITION", 0, false)
                    local sourceAILength = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_LENGTH", 0, false)
                    local sourceAIEnd = sourceAIPosition + sourceAILength
                    local sourceAIStartOffset = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_STARTOFFS", 0, false)
                    local sourceAIStartBeats = timeToBeats(sourceAIPosition)

                    sourceAIs[i][j][AIIndex].poolID = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_POOL_ID", 0, false)
                    sourceAIs[i][j][AIIndex].unscaledPlayrate = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_PLAYRATE", 0, false)
                    sourceAIs[i][j][AIIndex].playrate = sourceAIs[i][j][AIIndex].unscaledPlayrate / regionPlayrate
                    sourceAIs[i][j][AIIndex].baseline = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_BASELINE", 0, false)
                    sourceAIs[i][j][AIIndex].amplitude = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_AMPLITUDE", 0, false)
                    sourceAIs[i][j][AIIndex].loopSource = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_LOOPSRC", 0, false)

                    sourceAIs[i][j][AIIndex].startSpacingBeats = (sourceAIStartBeats - regionStartBeats) * regionPlayrate
                    sourceAIs[i][j][AIIndex].startSpacingTime = (sourceAIPosition - getRegionStart(sourceRegion)) * regionPlayrate
                    sourceAIs[i][j][AIIndex].lengthBeats = (timeToBeats(sourceAIPosition + sourceAILength) - sourceAIStartBeats) * regionPlayrate
                    sourceAIs[i][j][AIIndex].lengthTime = sourceAILength * regionPlayrate
                    sourceAIs[i][j][AIIndex].unscaledLengthTime = sourceAILength
                    sourceAIs[i][j][AIIndex].startOffsetBeats = timeToBeats(sourceAIPosition - sourceAIStartOffset) - sourceAIStartBeats
                    sourceAIs[i][j][AIIndex].startOffsetTime = sourceAIStartOffset
                    sourceAIs[i][j][AIIndex].averageTempo = getAverageTempoOfRange(sourceAIPosition, sourceAIEnd)

                    AIIndex = AIIndex + 1
                end
            end
        end
    end

    reaperCMD(40769) -- unselect all tracks/items/envelope points
end

function pasteSourceAutomationItems(inputSourceRegion, inputDestinationRegion)
    reaperCMD(40769) -- unselect all tracks/items/envelope points

    selectChildTracks(inputSourceRegion)
    local sourceTracks = getSelectedTracks()
    selectChildTracks(inputDestinationRegion)
    local selectedTracks = getSelectedTracks()

    local sourceRegionPlayrate = getRegionPlayrate(inputSourceRegion)
    local destinationRegionPlayrate = getRegionPlayrate(inputDestinationRegion)

    local sourceRegionBeats = timeToBeats(getRegionStart(inputSourceRegion))
    local destinationRegionBeats = timeToBeats(getRegionStart(inputDestinationRegion))

    for i = 1, #sourceTracks do
        local beatAttachMode = getTrackBeatAttachMode(sourceTracks[i])

        for j = 1, #sourceEnvelopes[i] do
            currentEnvelope = reaper.GetTrackEnvelope(selectedTracks[i], j - 1)

            for k = 1, #sourceAIs[i][j] do
                local newAIPositionTime = 0
                local newAILengthTime = 0
                local newAIStartOffsetTime = 0
                local newAIPlayrate = 0

                if beatAttachMode == "time" then
                    newAIPositionTime = getRegionStart(inputDestinationRegion) + sourceAIs[i][j][k].startSpacingTime / destinationRegionPlayrate
                    newAILengthTime = sourceAIs[i][j][k].lengthTime / destinationRegionPlayrate

                    local newAIAverageTempo = getAverageTempoOfRange(newAIPositionTime, newAIPositionTime + newAILengthTime)
                    local newAITempoRatio = sourceAIs[i][j][k].averageTempo / newAIAverageTempo
                    newAIStartOffsetTime = sourceAIs[i][j][k].startOffsetTime
                    newAIPlayrate = sourceAIs[i][j][k].playrate * destinationRegionPlayrate

                elseif beatAttachMode == "all_beats" then
                    local newAIStartBeats = destinationRegionBeats + sourceAIs[i][j][k].startSpacingBeats / destinationRegionPlayrate
                    local newAIEndBeats = newAIStartBeats + sourceAIs[i][j][k].lengthBeats / destinationRegionPlayrate
                    newAIPositionTime = beatsToTime(newAIStartBeats)
                    newAILengthTime = beatsToTime(newAIEndBeats) - beatsToTime(newAIStartBeats)
                    newAIStartOffsetTime = newAIPositionTime - beatsToTime(newAIStartBeats + sourceAIs[i][j][k].startOffsetBeats)
                    newAIPlayrate = sourceAIs[i][j][k].playrate * destinationRegionPlayrate

                elseif beatAttachMode == "beats_pos_only" then
                    local newAIStartBeats = destinationRegionBeats + sourceAIs[i][j][k].startSpacingBeats / destinationRegionPlayrate
                    newAIPositionTime = beatsToTime(newAIStartBeats)
                    newAILengthTime = sourceAIs[i][j][k].unscaledLengthTime

                    local newAIAverageTempo = getAverageTempoOfRange(newAIPositionTime, newAIPositionTime + newAILengthTime)
                    local newAITempoRatio = sourceAIs[i][j][k].averageTempo / newAIAverageTempo
                    newAIStartOffsetTime = sourceAIs[i][j][k].startOffsetTime
                    newAIPlayrate = sourceAIs[i][j][k].unscaledPlayrate * newAITempoRatio
                end

                local newAIEndTime = newAIPositionTime + newAILengthTime

                local pasteCorrectionTime = 0
                if newAIPositionTime < getRegionLeftBound(inputDestinationRegion) and newAIEndTime >= getRegionLeftBound(inputDestinationRegion) then
                    pasteCorrectionTime = getRegionLeftBound(inputDestinationRegion) - newAIPositionTime
                    newAIStartOffsetTime = newAIStartOffsetTime + pasteCorrectionTime * newAIPlayrate
                    newAIPositionTime = newAIPositionTime + pasteCorrectionTime
                    newAILengthTime = newAILengthTime - pasteCorrectionTime
                end

                -- Make sure to trim any automation items that do get pasted so they don't exceed the
                -- bounds of the region.
                local lengthToEndOfRegion = getRegionRightBound(inputDestinationRegion) - newAIPositionTime
                newAILengthTime = math.min(newAILengthTime, lengthToEndOfRegion)

                -- Only paste automation items that don't start and end outside the bounds of the destination region.
                if newAIEndTime >= getRegionLeftBound(inputDestinationRegion) and newAIPositionTime < getRegionRightBound(inputDestinationRegion) then
                    -- Insert the new automation item and set its parameters to mimic those of the source region.
                    local newAutomationItemID = reaper.InsertAutomationItem(currentEnvelope, sourceAIs[i][j][k].poolID, newAIPositionTime, newAILengthTime)
                    reaper.GetSetAutomationItemInfo(currentEnvelope, newAutomationItemID, "D_STARTOFFS", newAIStartOffsetTime, true)
                    reaper.GetSetAutomationItemInfo(currentEnvelope, newAutomationItemID, "D_PLAYRATE", newAIPlayrate, true)
                    reaper.GetSetAutomationItemInfo(currentEnvelope, newAutomationItemID, "D_BASELINE", sourceAIs[i][j][k].baseline, true)
                    reaper.GetSetAutomationItemInfo(currentEnvelope, newAutomationItemID, "D_AMPLITUDE", sourceAIs[i][j][k].amplitude, true)
                    reaper.GetSetAutomationItemInfo(currentEnvelope, newAutomationItemID, "D_LOOPSRC", sourceAIs[i][j][k].loopSource, true)
                end
            end
        end
    end

    reaperCMD(40769) -- unselect all tracks/items/envelope points
end

function regionHasChildItems(inputRegion)
    local previouslySelectedItems = getSelectedItems()
    reaperCMD(40289) -- unselect all items

    selectChildItems(inputRegion)
    local regionHasChildItems = #getSelectedItems() > 0

    restoreSelectedItems(previouslySelectedItems)

    return regionHasChildItems
end

function cleanAutomation(inputRegion)
    reaperCMD(40769) -- unselect all tracks/items/envelope points

    local edgePointCleanupRange = 0.0001

    setItemSelected(inputRegion, true)
    reaperCMD(41128) -- select previous adjacent non-overlapping item
    local adjacentLeftItem = getSelectedItems()
    local activeRegionIsAdjacentLeft = #getSelectedItems() > 0 and regionHasChildItems(adjacentLeftItem[1])
    reaperCMD(40289) -- unselect all items

    setItemSelected(inputRegion, true)
    reaperCMD(41127) -- select next adjacent non-overlapping item
    local adjacentRightItem = getSelectedItems()
    local activeRegionIsAdjacentRight = #getSelectedItems() > 0 and regionHasChildItems(adjacentRightItem[1])
    reaperCMD(40289) -- unselect all items

    selectChildTracks(inputRegion)
    local selectedTracks = getSelectedTracks()
    for i = 1, #selectedTracks do
        for j = 1, reaper.CountTrackEnvelopes(selectedTracks[i]) do
            local currentEnvelope = reaper.GetTrackEnvelope(selectedTracks[i], j - 1)

            -- It is better to create a new automation item to soak up the bare automation and then delete it.
            local newAI = reaper.InsertAutomationItem(currentEnvelope, -1, getRegionEffectiveStart(inputRegion), getRegionLength(inputRegion))
            reaper.GetSetAutomationItemInfo(currentEnvelope, newAI, "D_UISEL", 1, true)
            reaperCMD(42086) -- delete automation items

            if not activeRegionIsAdjacentLeft then
                reaper.DeleteEnvelopePointRange(currentEnvelope, getRegionLeftBound(inputRegion) - edgePointCleanupRange, getRegionLeftBound(inputRegion) + edgePointCleanupRange)
            end

            if not activeRegionIsAdjacentRight then
                reaper.DeleteEnvelopePointRange(currentEnvelope, getRegionRightBound(inputRegion) - edgePointCleanupRange, getRegionRightBound(inputRegion) + edgePointCleanupRange)
            end
        end
    end

    reaperCMD(40769) -- unselect all tracks/items/envelope points
end

function removeAutomationItems(inputRegion)
    reaperCMD(40769) -- unselect all tracks/items/envelope points

    selectChildTracks(inputRegion)

    local selectedTracks = getSelectedTracks()
    for i = 1, #selectedTracks do
        for j = 1, reaper.CountTrackEnvelopes(selectedTracks[i]) do
            reaperCMD(40769) -- unselect all tracks/items/envelope points
            local currentEnvelope = reaper.GetTrackEnvelope(selectedTracks[i], j - 1)

            for k = 1, reaper.CountAutomationItems(currentEnvelope) do
                local automationItemPosition = reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_POSITION", 0, false)
                if timeIsWithinRegion(inputRegion, automationItemPosition) then
                    reaper.GetSetAutomationItemInfo(currentEnvelope, k - 1, "D_UISEL", 1, true)
                end
            end

            reaperCMD(42086) -- delete automation items
        end
    end

    reaperCMD(40769) -- unselect all tracks/items/envelope points
end

function showAllTracksInRegion(inputRegion)
    selectChildTracks(inputRegion)
    reaperCMD("_SWSTL_BOTH")
end

function selectAllTracksThatMatchRegionName(inputRegion)
    local regionName = reaper.GetTakeName(getItemActiveTake(inputRegion))

    local trackCount = reaper.CountTracks(0)
    for i = 1, trackCount do
        local currentTrack = reaper.GetTrack(0, i - 1)
        local _, currentTrackName = reaper.GetSetMediaTrackInfo_String(currentTrack, "P_NAME", "", false);

        local trackRegionTagWithUnderscore = string.match(currentTrackName, ".+[_]")
        local trackRegionTag = nil

        if trackRegionTagWithUnderscore ~= nil then
            trackRegionTag = string.sub(trackRegionTagWithUnderscore, 1, -2)
        end

        if trackRegionTag == regionName then
            setTrackSelected(currentTrack, true)
        end
    end
end

function selectAllChildTracksIncludingIgnored(inputRegion)
    local parentTrack = getItemTrack(inputRegion)
    setOnlyTrackSelected(parentTrack)
    reaperCMD("_SWS_SELCHILDREN")
    selectAllTracksThatMatchRegionName(inputRegion)

    -- This will select the children of the tracks that match the region name.
    -- If you don't want a child track to be selected then you can add the
    -- ignore symbol to the beginning of the name.
    reaperCMD("_SWS_SELCHILDREN2")
end

function selectChildTracks(inputRegion)
    selectAllChildTracksIncludingIgnored(inputRegion)
    unselectIgnoredTracks()
end

function selectChildItems(inputRegion)
    reaperCMD(40769) -- unselect all tracks/items/envelope points
    selectChildTracks(inputRegion)

    setItemSelected(inputRegion, true)
    reaperCMD(40290) -- set time selection to items
    reaperCMD(40718) -- select all items on selected tracks in current time selection
    setItemSelected(inputRegion, false)

    unselectItemsThatStartOutsideOfRegion(inputRegion)
end

function unselectChildItems(inputRegion)
    local selectedChildren = getSelectedItems()

    for i = 1, #selectedChildren do
        if itemIsWithinRegion(inputRegion, selectedChildren[i]) then
            setItemSelected(selectedChildren[i], false)
        end
    end
end

local copiedItemStats = {}
function copyChildItems(inputRegion)
    selectChildItems(inputRegion)
    local selectedItems = getSelectedItems()
    local itemsWereCopied = #selectedItems > 0

    local itemPasteOffset = nil
    local pasteItemLeftBound = nil
    local pasteTrackNumber = nil
    local pasteTrackOffset = nil

    if itemsWereCopied then
        itemPasteOffset = getItemPosition(selectedItems[1]) - getRegionStart(inputRegion)
        pasteItemLeftBound = getItemLeftBound(selectedItems[1])
        pasteTrackNumber = getItemTrackNumber(selectedItems[1])

        for i = 1, #selectedItems do
            copiedItemStats[i] = {}
            copiedItemStats[i].startOffsetBeats = (timeToBeats(getItemPosition(selectedItems[i])) - timeToBeats(getRegionStart(inputRegion))) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].startOffsetTime = (getItemPosition(selectedItems[i]) - getRegionStart(inputRegion)) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].lengthBeats = getItemLengthBeats(selectedItems[i]) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].unscaledLengthTime = getItemLength(selectedItems[i])
            copiedItemStats[i].lengthTime = getItemLength(selectedItems[i]) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].snapOffsetBeats = (timeToBeats(getItemLeftBound(selectedItems[i]) + getItemSnapOffset(selectedItems[i])) - timeToBeats(getItemLeftBound(selectedItems[i]))) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].snapOffsetPercent = getItemSnapOffset(selectedItems[i]) / getItemLength(selectedItems[i])
            copiedItemStats[i].fadeIn = getItemFadeIn(selectedItems[i]) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].fadeInBeats = getItemFadeInBeats(selectedItems[i]) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].fadeOut = getItemFadeOut(selectedItems[i]) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].fadeOutBeats = getItemFadeOutBeats(selectedItems[i]) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].autoFadeIn = getItemAutoFadeIn(selectedItems[i]) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].autoFadeInBeats = getItemAutoFadeInBeats(selectedItems[i]) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].autoFadeOut = getItemAutoFadeOut(selectedItems[i]) * getRegionPlayrate(inputRegion)
            copiedItemStats[i].autoFadeOutBeats = getItemAutoFadeOutBeats(selectedItems[i]) * getRegionPlayrate(inputRegion)

            for j = 1, reaper.CountTakes(selectedItems[i]) do
                copiedItemStats[i][j] = {}

                local currentTake = getItemTake(selectedItems[i], j - 1)
                copiedItemStats[i][j].playrate = reaper.GetMediaItemTakeInfo_Value(currentTake, "D_PLAYRATE") / getRegionPlayrate(inputRegion)
                copiedItemStats[i][j].pitch = reaper.GetMediaItemTakeInfo_Value(currentTake, "D_PITCH") - getRegionPitch(inputRegion)

                local numTakeStretchMarkers = reaper.GetTakeNumStretchMarkers(currentTake)
                for k = 1, numTakeStretchMarkers do
                    copiedItemStats[i][j][k] = {}
                    local _, stretchMarkerPositionTime, stretchMarkerSourcePositionTime = reaper.GetTakeStretchMarker(currentTake, k - 1)

                    copiedItemStats[i][j][k].positionBeats = (timeToBeats(getItemPosition(selectedItems[i]) + stretchMarkerPositionTime / reaper.GetMediaItemTakeInfo_Value(currentTake, "D_PLAYRATE")) - timeToBeats(getItemPosition(selectedItems[i]))) * getRegionPlayrate(inputRegion)

                    copiedItemStats[i][j][k].sourcePositionTime = stretchMarkerSourcePositionTime
                end
            end

            copiedItemStats[i].averageTempo = getAverageTempoOfItem(selectedItems[i])

            if getItemLeftBound(selectedItems[i]) < pasteItemLeftBound then
                itemPasteOffset = getItemPosition(selectedItems[i]) - getRegionStart(inputRegion)
                pasteItemLeftBound = getItemLeftBound(selectedItems[i])
            end

            pasteTrackNumber = math.min(pasteTrackNumber, getItemTrackNumber(selectedItems[i]))
        end

        pasteTrackOffset = pasteTrackNumber - getItemTrackNumber(inputRegion)

        reaperCMD(40698) -- copy items
        reaperCMD(40289) -- unselect all items
    end

    return itemsWereCopied, itemPasteOffset, pasteTrackOffset
end

function removeChildItems(inputRegion)
    selectChildItems(inputRegion)

    reaperCMD(40006) -- remove items
end

function removeItemsOutsideOfRegion(inputRegion, items)
    reaperCMD(40289) -- unselect all items

    for i = 1, #items do
        if itemIsValid(items[i]) and not itemIsWithinRegion(inputRegion, items[i]) then
            setItemSelected(items[i], true)
        end
    end

    reaperCMD(40006) -- remove items
    restoreSelectedItems(items)
end

function trimAndApplyFadesIfPresent(inputRegion, items)
    restoreSelectedItems(items)

    if getRegionFadeIn(inputRegion) > 0 then
        reaper.SetEditCurPos(getRegionLeftBound(inputRegion), false, false)
        reaperCMD(40757) -- split items at edit cursor (no change selection)
    end

    if getRegionFadeOut(inputRegion) > 0 then
        reaper.SetEditCurPos(getRegionRightBound(inputRegion), false, false)
        reaperCMD(40757) -- split items at edit cursor (no change selection)
    end

    return getSelectedItems()
end

function rangeExperiencesTempoChanges(leftTime, rightTime)
    local numMarkersInProject = reaper.CountTempoTimeSigMarkers(0)

    if numMarkersInProject <= 1 then
        return false

    else
        local tempoMarkers = {}

        local timePeriod = rightTime - leftTime

        local leftMostMarker = reaper.FindTempoTimeSigMarker(0, leftTime)
        local rightMostMarker = reaper.FindTempoTimeSigMarker(0, rightTime)
        local numMarkers = 1 + rightMostMarker - leftMostMarker

        for i = 1, numMarkers + 1 do
            tempoMarkers[i] = {}

            local currentMarkerIndex = leftMostMarker + i - 1

            local _
            _, tempoMarkers[i].time, tempoMarkers[i].measure, tempoMarkers[i].beat, tempoMarkers[i].bpm, tempoMarkers[i].numerator, tempoMarkers[i].denominator, tempoMarkers[i].isLinear = reaper.GetTempoTimeSigMarker(0, currentMarkerIndex)

            if i > 1 then
                if tempoMarkers[i].bpm ~= tempoMarkers[i - 1].bpm then
                    if i == numMarkers + 1 then
                        if tempoMarkers[i - 1].isLinear then
                            return true
                        end
                    else
                        return true
                    end
                end
            end
        end
    end

    return false
end

function itemExperiencesTempoChanges(item)
    return rangeExperiencesTempoChanges(getItemLeftBound(item), getItemRightBound(item))
end

function getAverageTempoOfRange(leftTime, rightTime)
    local numMarkersInProject = reaper.CountTempoTimeSigMarkers(0)

    if numMarkersInProject <= 1 then
        return reaper.Master_GetTempo()

    elseif not rangeExperiencesTempoChanges(leftTime, rightTime) then
        local effectiveMarker = reaper.FindTempoTimeSigMarker(0, rightTime)
        local _, _, _, _, effectiveBPM, _, _, _ = reaper.GetTempoTimeSigMarker(0, effectiveMarker)

        return effectiveBPM

    else
        local tempoMarkers = {}

        local timePeriod = rightTime - leftTime

        local leftMostMarker = reaper.FindTempoTimeSigMarker(0, leftTime)
        local rightMostMarker = reaper.FindTempoTimeSigMarker(0, rightTime)
        local numMarkers = 1 + rightMostMarker - leftMostMarker

        for i = 1, numMarkers + 1 do
            tempoMarkers[i] = {}

            local currentMarkerIndex = leftMostMarker + i - 1

            local _
            _, tempoMarkers[i].time, tempoMarkers[i].measure, tempoMarkers[i].beat, tempoMarkers[i].bpm, tempoMarkers[i].numerator, tempoMarkers[i].denominator, tempoMarkers[i].isLinear = reaper.GetTempoTimeSigMarker(0, currentMarkerIndex)

            if i == 2 then
                if tempoMarkers[i - 1].isLinear then
                    local totalTimeOfRamp = tempoMarkers[i].time - tempoMarkers[i - 1].time
                    local itemStartTimeRatio = (leftTime - tempoMarkers[i - 1].time) / totalTimeOfRamp
                    local tempoDifferenceOfRamp = tempoMarkers[i].bpm - tempoMarkers[i - 1].bpm
                    local tempoAtItemStart = itemStartTimeRatio * tempoDifferenceOfRamp + tempoMarkers[i - 1].bpm

                    tempoMarkers[i - 1].bpm = tempoAtItemStart
                end

                tempoMarkers[i - 1].time = leftTime
            end

            if i == numMarkers + 1 then
                if tempoMarkers[i - 1].isLinear then
                    local totalTimeOfRamp = tempoMarkers[i].time - tempoMarkers[i - 1].time
                    local itemEndTimeRatio = (rightTime - tempoMarkers[i - 1].time) / totalTimeOfRamp
                    local tempoDifferenceOfRamp = tempoMarkers[i].bpm - tempoMarkers[i - 1].bpm
                    local tempoAtItemEnd = itemEndTimeRatio * tempoDifferenceOfRamp + tempoMarkers[i - 1].bpm

                    tempoMarkers[i].bpm = tempoAtItemEnd
                end

                if currentMarkerIndex >= numMarkersInProject then
                    tempoMarkers[i].bpm = tempoMarkers[i - 1].bpm
                end

                tempoMarkers[i].time = rightTime
            end
        end

        local outputTempo = 0

        for i = 2, numMarkers + 1 do
            local markerTimeRatio = (tempoMarkers[i].time - tempoMarkers[i - 1].time) / timePeriod
            local markerEffectiveTempo = tempoMarkers[i - 1].bpm

            if tempoMarkers[i - 1].isLinear then
                markerEffectiveTempo = (tempoMarkers[i].bpm + markerEffectiveTempo) / 2
            end

            local markerTempoAdditive = markerTimeRatio * markerEffectiveTempo

            outputTempo = outputTempo + markerTempoAdditive
        end

        return outputTempo
    end
end

function getAverageTempoOfItem(item)
    return getAverageTempoOfRange(getItemLeftBound(item), getItemRightBound(item))
end

-- This function is extremely important. It basically goes through all of the items
-- that were just pasted in a region and scales and pitches them according to
-- your track/item timing settings.
function adjustItemParamsToMatchRegion(sourceRegion, inputRegion, items)
    reaperCMD(40289) -- unselect all items

    local sourcePlayrate = getRegionPlayrate(sourceRegion)
    local regionPitch = getRegionPitch(inputRegion)
    local regionPlayrate = getRegionPlayrate(inputRegion)

    local sourceRegionHasTempoChanges = itemExperiencesTempoChanges(sourceRegion)
    local destinationRegionHasTempoChanges = itemExperiencesTempoChanges(inputRegion)
    local eitherRegionHasTempoChanges = sourceRegionHasTempoChanges or destinationRegionHasTempoChanges

    local destinationRegionTempoDiffersFromSource = false
    if not eitherRegionHasTempoChanges then
        if getAverageTempoOfItem(sourceRegion) ~= getAverageTempoOfItem(inputRegion) then
            destinationRegionTempoDiffersFromSource = true
        end
    end

    local thereAreTempoChangesToConsider = destinationRegionTempoDiffersFromSource or eitherRegionHasTempoChanges

    for i = 1, #items do
        if itemIsValid(items[i]) then
            if sourcePlayrate ~= regionPlayrate or thereAreTempoChangesToConsider then
                local itemBeatAttachMode = getItemBeatAttachMode(items[i])

                local newItemStartTime = getRegionStart(inputRegion) + copiedItemStats[i].startOffsetTime / regionPlayrate
                local newItemLengthTime = copiedItemStats[i].unscaledLengthTime
                local newItemSnapOffsetTime = newItemLengthTime * copiedItemStats[i].snapOffsetPercent
                local newItemLeftBoundTime = newItemStartTime - newItemSnapOffsetTime

                if itemBeatAttachMode == "time" then
                    newItemLengthTime = copiedItemStats[i].lengthTime / regionPlayrate
                    newItemSnapOffsetTime = newItemLengthTime * copiedItemStats[i].snapOffsetPercent

                    reaper.SetMediaItemPosition(items[i], newItemLeftBoundTime, false)
                    reaper.SetMediaItemLength(items[i], newItemLengthTime, false)
                    reaper.SetMediaItemInfo_Value(items[i], "D_SNAPOFFSET", newItemSnapOffsetTime)

                    local autoFadeInTime = copiedItemStats[i].autoFadeIn / regionPlayrate
                    local fadeInTime = copiedItemStats[i].fadeIn / regionPlayrate
                    local autoFadeOutTime = copiedItemStats[i].autoFadeOut / regionPlayrate
                    local fadeOutTime = copiedItemStats[i].fadeOut / regionPlayrate

                    reaper.SetMediaItemInfo_Value(items[i], "D_FADEINLEN_AUTO", autoFadeInTime)
                    reaper.SetMediaItemInfo_Value(items[i], "D_FADEINLEN", fadeInTime)
                    reaper.SetMediaItemInfo_Value(items[i], "D_FADEOUTLEN_AUTO", autoFadeOutTime)
                    reaper.SetMediaItemInfo_Value(items[i], "D_FADEOUTLEN", fadeOutTime)

                    for j = 1, reaper.CountTakes(items[i]) do
                        local currentTake = getItemTake(items[i], j - 1)
                        local takePlayrate = copiedItemStats[i][j].playrate * regionPlayrate

                        reaper.SetMediaItemTakeInfo_Value(currentTake, "D_PLAYRATE", takePlayrate)
                    end

                else
                    local newItemStartBeats = timeToBeats(getRegionStart(inputRegion)) + copiedItemStats[i].startOffsetBeats / regionPlayrate
                    newItemStartTime = beatsToTime(newItemStartBeats)
                    newItemLeftBoundTime = newItemStartTime - newItemSnapOffsetTime

                    if itemBeatAttachMode == "beats_pos_only" then
                        reaper.SetMediaItemPosition(items[i], newItemLeftBoundTime, false)

                        if getItemType(items[i]) == "midi" then
                            reaper.SetMediaItemLength(items[i], newItemLengthTime, false)
                            reaper.SetMediaItemInfo_Value(items[i], "D_SNAPOFFSET", newItemSnapOffsetTime)
                        end

                    -- Beats (position, length, rate) is the most complicated case since
                    -- everything has to be scaled correctly.
                    else
                        local newItemLengthBeats = copiedItemStats[i].lengthBeats / regionPlayrate
                        local newItemSnapOffsetBeats = copiedItemStats[i].snapOffsetBeats / regionPlayrate
                        local newItemLeftBoundBeats = newItemStartBeats - newItemSnapOffsetBeats
                        newItemLeftBoundTime = beatsToTime(newItemLeftBoundBeats)
                        local newItemRightBoundBeats = newItemLeftBoundBeats + newItemLengthBeats
                        local newItemRightBoundTime = beatsToTime(newItemRightBoundBeats)
                        newItemLengthTime = newItemRightBoundTime - newItemLeftBoundTime
                        newItemSnapOffsetTime = beatsToTime(newItemLeftBoundBeats + newItemSnapOffsetBeats) - newItemLeftBoundTime

                        reaper.SetMediaItemPosition(items[i], newItemLeftBoundTime, false)
                        reaper.SetMediaItemLength(items[i], newItemLengthTime, false)
                        reaper.SetMediaItemInfo_Value(items[i], "D_SNAPOFFSET", newItemSnapOffsetTime)

                        local autoFadeInTime = beatsToTime(newItemLeftBoundBeats + copiedItemStats[i].autoFadeInBeats / regionPlayrate) - newItemLeftBoundTime
                        local fadeInTime = beatsToTime(newItemLeftBoundBeats + copiedItemStats[i].fadeInBeats / regionPlayrate) - newItemLeftBoundTime
                        local autoFadeOutTime = newItemRightBoundTime - beatsToTime(newItemRightBoundBeats - copiedItemStats[i].autoFadeOutBeats / regionPlayrate)
                        local fadeOutTime = newItemRightBoundTime - beatsToTime(newItemRightBoundBeats - copiedItemStats[i].fadeOutBeats / regionPlayrate)

                        reaper.SetMediaItemInfo_Value(items[i], "D_FADEINLEN_AUTO", autoFadeInTime)
                        reaper.SetMediaItemInfo_Value(items[i], "D_FADEINLEN", fadeInTime)
                        reaper.SetMediaItemInfo_Value(items[i], "D_FADEOUTLEN_AUTO", autoFadeOutTime)
                        reaper.SetMediaItemInfo_Value(items[i], "D_FADEOUTLEN", fadeOutTime)

                        local tempoRatio = 1
                        if getItemType(items[i]) == "audio" then
                            local newItemAverageTempo = getAverageTempoOfItem(items[i])
                            tempoRatio = newItemAverageTempo / copiedItemStats[i].averageTempo
                        end

                        for j = 1, reaper.CountTakes(items[i]) do
                            local currentTake = getItemTake(items[i], j - 1)
                            local numTakeStretchMarkers = reaper.GetTakeNumStretchMarkers(currentTake)

                            if numTakeStretchMarkers <= 0 then
                                local takePlayrate = copiedItemStats[i][j].playrate * tempoRatio * regionPlayrate
                                reaper.SetMediaItemTakeInfo_Value(currentTake, "D_PLAYRATE", takePlayrate)
                            else
                                local takePlayrate = copiedItemStats[i][j].playrate * regionPlayrate
                                reaper.SetMediaItemTakeInfo_Value(currentTake, "D_PLAYRATE", takePlayrate)

                                -- We have to go through and delete all of the preset stretch markers first.
                                -- If we don't, we run the risk of them not being set in the right locations
                                -- because of other stretch markers getting in the way.
                                for k = 1, numTakeStretchMarkers do
                                    reaper.DeleteTakeStretchMarkers(currentTake, k - 1, numTakeStretchMarkers)
                                end

                                for k = 1, numTakeStretchMarkers do
                                    local newStretchMarkerPosition = beatsToTime(timeToBeats(getItemPosition(items[i])) + copiedItemStats[i][j][k].positionBeats / regionPlayrate) - getItemPosition(items[i])

                                    reaper.SetTakeStretchMarker(currentTake, -1, newStretchMarkerPosition * takePlayrate, copiedItemStats[i][j][k].sourcePositionTime)
                                end
                            end
                        end
                    end
                end
            end

            for j = 1, reaper.CountTakes(items[i]) do
                local currentTake = getItemTake(items[i], j - 1)

                reaper.SetMediaItemTakeInfo_Value(currentTake, "D_PITCH", copiedItemStats[i][j].pitch + regionPitch)
            end
        end
    end
end

function pasteChildItems(sourceRegion, inputRegion, itemPasteOffset, pasteTrackOffset)
    reaperCMD(40289) -- unselect all items
    setOnlyTrackSelected(reaper.GetTrack(0, getItemTrackNumber(inputRegion) + pasteTrackOffset - 1))

    reaper.SetEditCurPos(getRegionStart(inputRegion) + itemPasteOffset, false, false)

    reaperCMD(40058) -- paste items
    local pastedItems = getSelectedItems()

    -- For some reason pasting like this via ReaScript is unreliable
    -- and will fail to paste randomly in some regions. Since this function is
    -- only run if there are items to paste, if there are no pasted items,
    -- we failed to paste and we should try again.
    while #pastedItems <= 0 do
        reaperCMD(40058) -- paste items
        pastedItems = getSelectedItems()
    end

    adjustItemParamsToMatchRegion(sourceRegion, inputRegion, pastedItems)
    pastedItems = trimAndApplyFadesIfPresent(inputRegion, pastedItems)
    removeItemsOutsideOfRegion(inputRegion, pastedItems)
    reaperCMD(40289) -- unselect all items

    return pastedItems
end

function clearRegion(inputRegion)
    -- The script doesn't work properly unless all of the tracks in the
    -- region are visible.
    showAllTracksInRegion(inputRegion)
    removeChildItems(inputRegion)
    cleanAutomation(inputRegion)
    removeAutomationItems(inputRegion)
end