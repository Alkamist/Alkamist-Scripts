package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local Reaper = require "Various Functions.Reaper Functions"
local FileManager = require "Pitch Correction.Classes.Class - FileManager"



local PitchGroup = {}

function PitchGroup:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    if o.item then
        o:setItem(o.item)
    end

    o.editOffset = o.editOffset or 0.0
    o.points = o.points or {}
    o.stretchMarkers = o.stretchMarkers or {}
    o.stretchMarkersWithBoundaries = o.stretchMarkersWithBoundaries or {}

    return o
end



function PitchGroup.prepareExtStateForPitchDetection(takeGUID, settings)
    reaper.SetExtState("Alkamist_PitchCorrection", "TAKEGUID", takeGUID, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "WINDOWSTEP", settings.windowStep, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "MINFREQ", settings.minimumFrequency, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "MAXFREQ", settings.maximumFrequency, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "YINTHRESH", settings.YINThresh, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "OVERLAP", settings.overlap, false)
    reaper.SetExtState("Alkamist_PitchCorrection", "LOWRMSLIMDB", settings.lowRMSLimitdB, false)
end

function PitchGroup:getMinTimePerPoint()
    local prevPoint = nil
    local minTimePerPoint = self.length

    for index, point in ipairs(self.points) do
        if prevPoint then
            local timeFromLastPoint = point.time - prevPoint.time
            minTimePerPoint = math.min(minTimePerPoint, timeFromLastPoint)
        end

        prevPoint = point
    end

    return minTimePerPoint
end

function PitchGroup:analyze(settings)
    local analyzerID = Reaper.getEELCommandID("Pitch Analyzer")

    if not analyzerID then
        reaper.MB("Pitch Analyzer.eel not found!", "Error!", 0)
        return 0
    end

    Lua.arrayRemove(self.points, function(t, i)
        local value = t[i]

        return true
    end)

    self.points = {}

    PitchGroup.prepareExtStateForPitchDetection(self.takeGUID, settings)
    Reaper.reaperCMD(analyzerID)

    local analysisString = "<PITCHDATA " .. string.format("%f %f\n", self.startOffset, self.startOffset + self.length) ..
                                reaper.GetExtState("Alkamist_PitchCorrection", "PITCHDATA") ..
                            ">\n"

    local tempData = FileManager:new( { data = analysisString } )

    self.points = tempData:getPitchPoints(self)
    self.minTimePerPoint = self:getMinTimePerPoint()

    self:savePoints()
end

function PitchGroup.getCombinedGroup(favoredGroup, secondaryGroup)
    local favoredLeftBound = favoredGroup.startOffset
    local favoredRightBound = favoredLeftBound + favoredGroup.length

    local secondaryLeftBound = secondaryGroup.startOffset
    local secondaryRightBound = secondaryLeftBound + secondaryGroup.length

    local groupsAreOverlapping = favoredLeftBound >= secondaryLeftBound and favoredLeftBound <= secondaryRightBound
                              or favoredRightBound >= secondaryLeftBound and favoredRightBound <= secondaryRightBound

                              or secondaryLeftBound >= favoredLeftBound and secondaryLeftBound <= favoredRightBound
                              or secondaryRightBound >= favoredLeftBound and secondaryRightBound <= favoredRightBound

    if groupsAreOverlapping then

        local outputGroup = PitchGroup:new( {

            startOffset = math.min(favoredGroup.startOffset, secondaryGroup.startOffset),
            length = math.max(favoredGroup.length, secondaryGroup.length),
            points = {}

        } )

        local favoredPointsWereInserted = false
        for secondaryIndex, secondaryPoint in ipairs(secondaryGroup.points) do

            if secondaryPoint.time < favoredLeftBound or secondaryPoint.time > favoredRightBound then
                table.insert(outputGroup.points, secondaryPoint)
            end

            if not favoredPointsWereInserted then

                if secondaryPoint.time >= favoredLeftBound then

                    for favoredIndex, favoredPoint in ipairs(favoredGroup.points) do
                        table.insert(outputGroup.points, favoredPoint)
                    end

                    favoredPointsWereInserted = true

                end
            end
        end

        return outputGroup, true

    end

    return favoredGroup, false
end

function PitchGroup.getCombinedGroups(favoredGroup, secondaryGroups)
    local outputGroups = {}

    if #secondaryGroups > 0 then

        for index, prevGroup in ipairs(secondaryGroups) do
            local dataGroupCombined = false
            favoredGroup, dataGroupCombined = PitchGroup.getCombinedGroup(favoredGroup, prevGroup)

            if not dataGroupCombined then
                table.insert(outputGroups, prevGroup)
            end

            if index == #secondaryGroups then
                table.insert(outputGroups, favoredGroup)
            end
        end

    else
        table.insert(outputGroups, favoredGroup)
    end

    return outputGroups
end

function PitchGroup:getEnvelope()
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(self.take, "Pitch")

    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        Reaper.reaperCMD("_S&M_TAKEENV10") -- Show and unbypass take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(self.take, "Pitch")
    end

    Reaper.reaperCMD("_S&M_TAKEENVSHOW8") -- Hide take pitch envelope

    return pitchEnvelope
end

function PitchGroup:setItem(item)
    if Reaper.getItemType(item) ~= "audio" then return end

    self.item = item
    self.take = reaper.GetActiveTake(self.item)
    self.takeName = reaper.GetTakeName(self.take)
    self.takeGUID = reaper.BR_GetMediaItemTakeGUID(self.take)
    self.takeSource = reaper.GetMediaItemTake_Source(self.take)
    self.takeFileName = Lua.getFileName( reaper.GetMediaSourceFileName(self.takeSource, "") )
    self.length = reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")
    self.leftTime = reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")
    self.rightTime = self.leftTime + self.length
    self.playrate = reaper.GetMediaItemTakeInfo_Value(self.take, "D_PLAYRATE")
    self.startOffset = reaper.GetMediaItemTakeInfo_Value(self.take, "D_STARTOFFS")

    self.envelope = self:getEnvelope()

    _, _, self.takeSourceLength = reaper.PCM_Source_GetSectionInfo(self.takeSource)

    self.stretchMarkers = Reaper.getStretchMarkers(self.take)
    self:generateBoundaryMarkers()
    self.points = self:loadSavedPoints()
    self.minTimePerPoint = self:getMinTimePerPoint()

    --local startTime = reaper.time_precise()
    --FileManager.loadPitchGroup(self.takeFileName .. ".pitch")
    --FileManager.savePitchGroup(self)
    --msg(reaper.time_precise() - startTime)
end

function PitchGroup:timeIsWithinPitchContent(time)
    if #self.points < 1 then return end

    return time >= self.points[1].relativeTime and time <= self.points[#self.points].relativeTime
end

function PitchGroup:getPointIndexByTime(time, findLeft)
    local numPoints = #self.points

    if numPoints < 1 then
        return nil
    end

    local firstPoint = self.points[1]
    local lastPoint = self.points[numPoints]
    local totalTime = lastPoint.relativeTime - firstPoint.relativeTime

    local bestGuessIndex = math.floor(numPoints * time / totalTime)
    bestGuessIndex = Lua.clamp(bestGuessIndex, 1, numPoints)

    local guessPoint = self.points[bestGuessIndex]
    local prevGuessIsLeftOfTime = guessPoint.relativeTime <= time

    repeat
        guessPoint = self.points[bestGuessIndex]

        local guessError = math.abs(guessPoint.relativeTime - time)
        local guessIsLeftOfTime = guessPoint.relativeTime <= time

        if guessIsLeftOfTime then
            -- You are going right and the target is still to the right.
            if prevGuessIsLeftOfTime then
                bestGuessIndex = bestGuessIndex + 1

            -- You were going left and passed the target.
            else
                if findLeft then
                    return bestGuessIndex
                else
                    return bestGuessIndex + 1
                end
            end

        else
            -- You are going left and the target is still to the left.
            if not prevGuessIsLeftOfTime then
                bestGuessIndex = bestGuessIndex - 1

            -- You were going right and passed the target.
            else
                if not findLeft then
                    return bestGuessIndex
                else
                    return bestGuessIndex - 1
                end
            end

        end

        prevGuessIsLeftOfTime = guessIsLeftOfTime

    until bestGuessIndex < 1 or bestGuessIndex > numPoints

    if bestGuessIndex < 1 then
        return 1

    elseif bestGuessIndex > numPoints then
        return numPoints
    end

    return 1
end



function PitchGroup.getPitchGroupsFromItems(items)
    local pitchGroups = {}

    Reaper.setUIRefresh(false)

    local selectedItems = Reaper.getSelectedItems()
    Reaper.reaperCMD(40289) -- Unselect all items

    for index, item in pairs(items) do
        if reaper.ValidatePtr(item, "MediaItem*") then
            if Reaper.getItemType(item) == "audio" then
                Reaper.setItemSelected(item, true)

                table.insert( pitchGroups, PitchGroup:new( { item = item } ) )

                Reaper.setItemSelected(item, false)
            end
        end
    end

    Reaper.restoreSelectedItems(selectedItems)

    Reaper.setUIRefresh(true)

    return pitchGroups
end

function PitchGroup:generateBoundaryMarkers()
    local tempMarkers = Lua.copyTable(self.stretchMarkers)

    local leftBound = Reaper.getSourcePosition(self.take, 0.0)
    local rightBound = Reaper.getSourcePosition(self.take, self.length)

    local leftBoundIndex = nil
    for index, marker in ipairs(tempMarkers) do
        if marker.srcPos > leftBound then
            leftBoundIndex = leftBoundIndex or index
        end
    end
    leftBoundIndex = leftBoundIndex or 1

    local leftRate = 1.0
    if leftBoundIndex > 1 then leftRate = tempMarkers[leftBoundIndex - 1].rate end

    table.insert(tempMarkers, leftBoundIndex, {
        pos = 0.0,
        srcPos = leftBound,
        rate = leftRate
    } )

    local rightBoundIndex = nil
    for index, marker in ipairs(tempMarkers) do
        if marker.srcPos > rightBound then
            rightBoundIndex = rightBoundIndex or index
        end
    end
    rightBoundIndex = rightBoundIndex or #tempMarkers + 1

    table.insert(tempMarkers, rightBoundIndex, {
        pos = self.length * self.playrate,
        srcPos = rightBound,
        rate = 1.0
    } )

    self.stretchMarkersWithBoundaries = tempMarkers
end

function PitchGroup:savePoints()
    local prevPitchGroups = self.data:getPitchGroups()

    for index, group in ipairs(prevPitchGroups) do
        group = PitchGroup:new(group)
    end

    local combinedGroups = PitchGroup.getCombinedGroups(Lua.copyTable(self), prevPitchGroups)

    local saveString = ""

    for index, group in ipairs(combinedGroups) do
        saveString = saveString .. group:getDataString()
    end

    reaper.SetProjExtState(0, "Alkamist_PitchCorrection", self.takeFileName, saveString)
end

function PitchGroup:loadSavedPoints()
    local savedPoints = {}

    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", self.takeFileName)
    self.data = FileManager:new( { data = extState } )

    savedPoints = self.data:getPitchPoints(self, tempMarkers)

    return savedPoints
end

function PitchGroup:getDataString()
    local pitchString = ""

    for pointIndex, point in ipairs(self.points) do
        pitchString = pitchString .. tostring(point.time) .. " " ..
                                     tostring(point.pitch) .. " " ..
                                     tostring(point.rms) .. "\n"
    end

    local dataString = "<PITCHDATA " .. tostring(self.startOffset) .. " " .. tostring(self.startOffset + self.length) .. "\n" ..
                            pitchString ..
                        ">\n"

    return dataString
end

return PitchGroup