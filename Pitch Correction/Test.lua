function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
--local TakeWithPitchPoints = require("Pitch Correction.TakeWithPitchPoints")
--
--local pointer = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))
--local test = TakeWithPitchPoints:new{ pointer = pointer }
--
--test:prepareToAnalyzePitch(shouldAnalyzeFullTakeSource)
--
--repeat
--    test:analyzePitch()
--until not test.isAnalyzingPitch
--
--msg(test.pitches:encodeAsString(test.pitchPointMembers))

--for k, v in pairs(test) do
--    msg(k)
--    msg(v)
--end

--local GUI = require("GUI.AlkamistGUI")
--local Button = require("GUI.Button")
--
--GUI:initialize{
--    title = "Alkamist Pitch Correction",
--    x = 400,
--    y = 200,
--    width = 1000,
--    height = 700,
--    dock = 0
--}
--GUI.backgroundColor = { 0.2, 0.2, 0.2 }
--
--local test1 = Button:new{
--    x = 100,
--    y = 100,
--    width = 80,
--    height = 25,
--    label = "Fix Errors",
--    --toggleOnClick = true
--}
--
--GUI.widgets = { test1 }
--GUI:run()