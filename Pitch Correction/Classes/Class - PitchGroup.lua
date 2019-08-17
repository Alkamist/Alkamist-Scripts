package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local Reaper = require "Various Functions.Reaper Functions"



------------------- Class -------------------

local PitchGroup = {}

function PitchGroup:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    if o.item then
        o:setItem(o.item)
    end

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

function PitchGroup:analyze(settings)
    local analyzerID = Reaper.getEELCommandID("Pitch Analyzer")

    if not analyzerID then
        reaper.MB("Pitch Analyzer.eel not found!", "Error!", 0)
        return 0
    end

    PitchGroup.prepareExtStateForPitchDetection(self.takeGUID, settings)
    Reaper.reaperCMD(analyzerID)

    local analysisString = reaper.GetExtState("Alkamist_PitchCorrection", "PITCHDATA")

    self.points = PitchGroup.getPointsFromString(analysisString)

    self:savePoints()
end

function PitchGroup.getDataStringFromHeader(fullDataString, dataHeader)
    local headerStart, headerEnd = string.find(fullDataString, dataHeader)
    local outputDataString = ""

    if headerStart and headerEnd then
        local searchIndex = headerEnd

        repeat

            local line = string.match(fullDataString, "([^\r\n]+)", searchIndex)
            if line == nil then break end
            if string.match(line, "PLAYRATE") then break end

            outputDataString = outputDataString .. line .. "\n"

            searchIndex = searchIndex + string.len(line) + 1

        until false
    end

    return outputDataString
end

function PitchGroup.getGroupsFromDataString(dataString)
    local outputGroups = {}
    local groupIndex = 1
    local searchIndex = 1
    local recordPointData = false

    repeat

        local line = string.match(dataString, "([^\r\n]+)", searchIndex)
        if line == nil then break end

        if line:match("<PITCHDATA") then
            local leftBound =  tonumber( line:match("<PITCHDATA ([%.%-%d]+) [%.%-%d]+") )
            local rightBound = tonumber( line:match("<PITCHDATA [%.%-%d]+ ([%.%-%d]+)") )

            outputGroups[groupIndex] = PitchGroup:new( {

                startOffset = leftBound,
                length = rightBound - leftBound,
                points = {}

            } )

            recordPointData = true
        end

        if line:match(">") and recordPointData then
            recordPointData = false
            groupIndex = groupIndex + 1
        end

        if recordPointData then
            local pointTime = tonumber( line:match("    ([%.%-%d]+) [%.%-%d]+ [%.%-%d]+") )

            if pointTime then
                local pointPitch = tonumber( line:match("    [%.%-%d]+ ([%.%-%d]+) [%.%-%d]+") )
                local pointRMS =   tonumber( line:match("    [%.%-%d]+ [%.%-%d]+ ([%.%-%d]+)") )

                table.insert(outputGroups[groupIndex].points, {

                    time = pointTime,
                    pitch = pointPitch,
                    rms = pointRMS

                })
            end
        end

        searchIndex = searchIndex + string.len(line) + 1

    until false

    return outputGroups
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

function PitchGroup.getCombinedGroups(favoredGroup, prevPitchGroups)
    local outputGroups = {}

    if #prevPitchGroups > 0 then

        for index, prevGroup in ipairs(prevPitchGroups) do
            local dataGroupCombined = false
            favoredGroup, dataGroupCombined = PitchGroup.getCombinedGroup(favoredGroup, prevGroup)

            if not dataGroupCombined then
                table.insert(outputGroups, prevGroup)
            end

            if index == #prevPitchGroups then
                table.insert(outputGroups, favoredGroup)
            end
        end

    else
        table.insert(outputGroups, favoredGroup)
    end

    return outputGroups
end

function PitchGroup:savePoints()
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", self.takeName)
    local dataHeader = self:getDataHeader()

    local dataStringFromHeader = PitchGroup.getDataStringFromHeader(extState, dataHeader)
    local prevPitchGroups = PitchGroup.getGroupsFromDataString(dataStringFromHeader)
    local combinedGroups = PitchGroup.getCombinedGroups(Lua.copyTable(self), prevPitchGroups)

    local saveString = dataHeader

    for index, group in ipairs(combinedGroups) do
        saveString = saveString .. group:getDataString()
    end

    local newExtState = string.gsub(extState, dataHeader .. dataStringFromHeader, "") .. saveString

    reaper.SetProjExtState(0, "Alkamist_PitchCorrection", self.takeName, newExtState)
end

function PitchGroup.getPointsFromDataStringWithinRange(dataString, leftBound, rightBound)
    local pointString = ""

    for line in dataString:gmatch("[^\r\n]+") do

        local pointTime = tonumber( line:match("    ([%.%-%d]+) [%.%-%d]+ [%.%-%d]+") )

        if pointTime then
            if pointTime >= leftBound and pointTime <= rightBound then
                pointString = pointString .. line .. "\n"
            end
        end

    end

    return PitchGroup.getPointsFromString(pointString)
end

function PitchGroup:getSavedPoints()
    local _, extState = reaper.GetProjExtState(0, "Alkamist_PitchCorrection", self.takeName)
    local dataHeader = self:getDataHeader()

    local dataStringFromHeader = PitchGroup.getDataStringFromHeader(extState, dataHeader)

    local leftBound = self.startOffset
    local rightBound = leftBound + self.length

    return PitchGroup.getPointsFromDataStringWithinRange(dataStringFromHeader, leftBound, rightBound)
end

function PitchGroup:getEnvelope()
    local pitchEnvelope = reaper.GetTakeEnvelopeByName(self.take, "Pitch")

    if not pitchEnvelope or not reaper.ValidatePtr2(0, pitchEnvelope, "TrackEnvelope*") then
        reaper.Main_OnCommand(41612, 0) -- Take: Toggle take pitch envelope
        pitchEnvelope = reaper.GetTakeEnvelopeByName(self.take, "Pitch")
    end

    return pitchEnvelope
end

function PitchGroup.getPointsFromString(pointString)
    local points = {}

    for line in pointString:gmatch("[^\r\n]+") do

        table.insert(points, {

            time =  tonumber( line:match("([%.%-%d]+) [%.%-%d]+ [%.%-%d]+") ),
            pitch = tonumber( line:match("[%.%-%d]+ ([%.%-%d]+) [%.%-%d]+") ),
            rms =   tonumber( line:match("[%.%-%d]+ [%.%-%d]+ ([%.%-%d]+)") )

        } )

    end

    return points
end

function PitchGroup.getPitchGroupsFromItems(items)
    local pitchGroups = {}

    for index, item in pairs(items) do
        if reaper.ValidatePtr(item, "MediaItem*") then
            table.insert( pitchGroups, PitchGroup:new( { item = item } ) )
        end
    end

    return pitchGroups
end

function PitchGroup:getDataHeader()
    local stretchMarkersString = ""

    for markerIndex, marker in ipairs(self.stretchMarkers) do
        stretchMarkersString = stretchMarkersString .. string.format("    %f %f\n", marker.pos, marker.srcPos)
    end

    local dataHeader = "PLAYRATE " .. self.playrate .. "\n" ..

                       "<STRETCHMARKERS\n" .. stretchMarkersString ..
                       ">\n"

    return dataHeader
end

function PitchGroup:getDataString()
    local pitchString = ""

    for pointIndex, point in ipairs(self.points) do
        pitchString = pitchString .. string.format("    %f %f %f\n", point.time, point.pitch, point.rms)
    end

    local dataString = "<PITCHDATA " .. string.format("%f %f\n", self.startOffset, self.startOffset + self.length) ..
                            pitchString ..
                        ">\n"

    return dataString
end

function PitchGroup:setItem(item)
    if Reaper.getItemType(item) == "midi" then return end

    self.item = item
    self.take = reaper.GetActiveTake(self.item)
    self.takeName = reaper.GetTakeName(self.take)
    self.takeGUID = reaper.BR_GetMediaItemTakeGUID(self.take)
    self.length = reaper.GetMediaItemInfo_Value(self.item, "D_LENGTH")
    self.leftTime = reaper.GetMediaItemInfo_Value(self.item, "D_POSITION")
    self.rightTime = self.leftTime + self.length
    self.playrate = reaper.GetMediaItemTakeInfo_Value(self.take, "D_PLAYRATE")
    self.startOffset = reaper.GetMediaItemTakeInfo_Value(self.take, "D_STARTOFFS")
    self.envelope = self:getEnvelope()
    self.stretchMarkers = Reaper.getStretchMarkers(self.take)
    self.points = self:getSavedPoints()
end

return PitchGroup