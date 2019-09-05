package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Lua = require "Various Functions.Lua Functions"
local Reaper = require "Various Functions.Reaper Functions"



local PitchGroup = {}

function PitchGroup:new(o)
    o = o or {}

    setmetatable(o, self)
    self.__index = self

    o.editOffset = o.editOffset or 0.0
    o.points = o.points or {}
    o.stretchMarkers = o.stretchMarkers or {}
    o.stretchMarkersWithBoundaries = o.stretchMarkersWithBoundaries or {}

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

function PitchGroup:getMinSourceTimePerPoint()
    local prevPoint = nil
    local minSourceTimePerPoint = self.takeSourceLength

    for index, point in ipairs(self.points) do
        if prevPoint then
            local timeFromLastPoint = point.sourceTime - prevPoint.sourceTime
            minSourceTimePerPoint = math.min(minSourceTimePerPoint, timeFromLastPoint)
        end

        prevPoint = point
    end

    return minSourceTimePerPoint
end

function PitchGroup.getCombinedGroup(favoredGroup, secondaryGroup)
    local favoredLeftBound = favoredGroup.startOffset
    local favoredRightBound = favoredGroup.startOffset + favoredGroup.length

    local secondaryLeftBound = secondaryGroup.startOffset
    local secondaryRightBound = secondaryGroup.startOffset + secondaryGroup.length

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

        outputGroup.takeFileName = favoredGroup.takeFileName

        local favoredPointsWereInserted = false
        for secondaryIndex, secondaryPoint in ipairs(secondaryGroup.points) do

            if secondaryPoint.sourceTime < favoredLeftBound or secondaryPoint.sourceTime > favoredRightBound then
                table.insert(outputGroup.points, secondaryPoint)
            end

            if not favoredPointsWereInserted then

                if secondaryPoint.sourceTime >= favoredLeftBound then

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
    self:loadSavedPoints()
    self.minTimePerPoint = self:getMinTimePerPoint()
    self.minSourceTimePerPoint = self:getMinSourceTimePerPoint()
end

function PitchGroup:timeIsWithinPitchContent(time)
    if #self.points < 1 then return end

    return time >= self.points[1].time and time <= self.points[#self.points].time
end

function PitchGroup:getPointIndexByTime(time, findLeft)
    local numPoints = #self.points

    if numPoints < 1 then
        return nil
    end

    local firstPoint = self.points[1]
    local lastPoint = self.points[numPoints]
    local totalTime = lastPoint.time - firstPoint.time

    local bestGuessIndex = math.floor(numPoints * time / totalTime)
    bestGuessIndex = Lua.clamp(bestGuessIndex, 1, numPoints)

    local guessPoint = self.points[bestGuessIndex]
    local prevGuessIsLeftOfTime = guessPoint.time <= time

    repeat
        guessPoint = self.points[bestGuessIndex]

        local guessError = math.abs(guessPoint.time - time)
        local guessIsLeftOfTime = guessPoint.time <= time

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



function PitchGroup.getPitchPointsFromExtState(pitchGroup)
    local pointString = reaper.GetExtState("Alkamist_PitchCorrection", "PITCHDATA")

    local pitchPoints = {}

    for line in pointString:gmatch("([^\r\n]+)") do

        local values = Lua.getStringValues(line)

        local pointTime = values[1] - pitchGroup.startOffset
        local sourceTime = Reaper.getSourcePosition(pitchGroup.take, pointTime)

        local point = {

            time = pointTime,
            sourceTime = sourceTime,
            pitch = values[2],
            rms = values[3]

        }

        table.insert(pitchPoints, point)
    end

    return pitchPoints
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

    self.points = PitchGroup.getPitchPointsFromExtState(self)
    self.minTimePerPoint = self:getMinTimePerPoint()
    self.minSourceTimePerPoint = self:getMinSourceTimePerPoint()

    self:savePoints()
end

function PitchGroup.getSaveString(pitchGroup)
    local pitchKeyString = "sourceTime pitch rms"
    local pitchString = ""

    for pointIndex, point in ipairs(pitchGroup.points) do
        pitchString = pitchString .. tostring(point.sourceTime) .. " " ..
                                     tostring(point.pitch) .. " " ..
                                     tostring(point.rms) .. "\n"
    end


    return "LEFTBOUND " .. tostring(pitchGroup.startOffset) .. "\n" ..

           "RIGHTBOUND " .. tostring(pitchGroup.startOffset + pitchGroup.length) .. "\n" ..

           "<PITCH " .. pitchKeyString .. "\n" ..
           pitchString ..
           ">\n"
end

function PitchGroup:savePoints()
    local prevPitchGroups = PitchGroup.loadAllPitchGroups(self.takeFileName .. ".pitch")

    for index, group in ipairs(prevPitchGroups) do
        group.takeFileName = self.takeFileName
    end

    local combinedGroups = PitchGroup.getCombinedGroups(Lua.copyTable(self), prevPitchGroups)

    local saveString = ""

    for index, group in ipairs(combinedGroups) do
        saveString = saveString .. PitchGroup.getSaveString(group)
    end


    local fullFileName = reaper.GetProjectPath("") .. "\\" .. self.takeFileName .. ".pitch"
    local file, err = io.open(fullFileName, "w")

    file:write(saveString)
end

function PitchGroup:loadSavedPoints()
    local fullFileName = reaper.GetProjectPath("") .. "\\" .. self.takeFileName .. ".pitch"

    local lines = Lua.getFileLines(fullFileName)

    self.points = {}

    local headerLeft = nil
    local headerRight = nil
    local keys = {}
    local recordPoints = false
    local pointIndex = 1

    local leftBound = Reaper.getSourcePosition(self.take, 0.0)
    local rightBound = Reaper.getSourcePosition(self.take, self.length)

    for lineNumber, line in ipairs(lines) do

        headerLeft = headerLeft or tonumber( line:match("LEFTBOUND ([%.%-%d]+)") )
        headerRight = headerRight or tonumber( line:match("RIGHTBOUND ([%.%-%d]+)") )

        if line:match(">") then
            recordPoints = false
            headerLeft = nil
            headerRight = nil
            keys = {}
        end

        if headerLeft and headerRight then

            if Lua.rangesOverlap( { left = headerLeft, right = headerRight },
                                  { left = leftBound, right = rightBound } ) then

                if line:match("<PITCH") then
                    recordPoints = true

                    for key in string.gmatch(line, " (%a+)") do
                        table.insert(keys, key)
                    end
                end

                if recordPoints then

                    local lineValues = Lua.getStringValues(line)

                    if #lineValues >= #keys then
                        local point = {}

                        for index, key in ipairs(keys) do
                            point[key] = lineValues[index]
                        end

                        if point.sourceTime >= leftBound and point.sourceTime <= rightBound then
                            self.points[pointIndex] = point
                            self.points[pointIndex].time = Reaper.getRealPosition(self.take, self.points[pointIndex].sourceTime)

                            pointIndex = pointIndex + 1
                        end
                    end
                end
            end
        end
    end

    table.sort(self.points, function(a, b) return a.sourceTime < b.sourceTime end)
end

function PitchGroup.loadAllPitchGroups(fileName)
    local fullFileName = reaper.GetProjectPath("") .. "\\" .. fileName

    local lines = Lua.getFileLines(fullFileName)

    local pitchGroups = {}

    local headerLeft = nil
    local headerRight = nil
    local keys = {}
    local recordPoints = false
    local pointIndex = 1
    local groupIndex = 1

    for lineNumber, line in ipairs(lines) do

        headerLeft = headerLeft or tonumber( line:match("LEFTBOUND ([%.%-%d]+)") )
        headerRight = headerRight or tonumber( line:match("RIGHTBOUND ([%.%-%d]+)") )

        if headerLeft and headerRight then

            if line:match("<PITCH") then
                pitchGroups[groupIndex] = {

                    startOffset = headerLeft,
                    length = headerRight - headerLeft,
                    points = {}

                }

                recordPoints = true
                pointIndex = 1

                for key in string.gmatch(line, " (%a+)") do
                    table.insert(keys, key)
                end
            end

            if line:match(">") then
                groupIndex = groupIndex + 1
                recordPoints = false
                headerLeft = nil
                headerRight = nil
                keys = {}
            end

            if recordPoints then

                local lineValues = Lua.getStringValues(line)

                if #lineValues >= #keys then
                    local point = {}

                    for index, key in ipairs(keys) do
                        point[key] = lineValues[index]
                    end

                    pitchGroups[groupIndex].points[pointIndex] = point
                    pitchGroups[groupIndex].points[pointIndex].time = pitchGroups[groupIndex].points[pointIndex].sourceTime

                    pointIndex = pointIndex + 1
                end
            end
        end
    end

    return pitchGroups
end

return PitchGroup