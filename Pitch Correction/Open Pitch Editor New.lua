package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Script: Set Lokasenna_GUI v2 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

local Alk = require "API.Alkamist API"
require "Pitch Correction.Pitch Editor New"
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Menubar.lua")()
GUI.req("Classes/Class - Knob.lua")()
GUI.req("Classes/Class - Window.lua")()

-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end

local guiDock, guiX, guiY, guiW, guiH = GUI.load_window_state("Alkamist_PitchCorrection", "windowState")

GUI.name = "Alkamist Pitch Correction"
GUI.dock = tonumber(guiDock) or 0
GUI.x = tonumber(guiX) or 500
GUI.y = tonumber(guiY) or 100
GUI.w = tonumber(guiW) or 1200
GUI.h = tonumber(guiH) or 700

local fonts = GUI.get_OS_fonts()
local elms = {}

--local menu_functions = {
--    analyzePitchGroups = function()
--        elms.pitch_editor:analyzePitchGroups(pdSettings)
--    end,
--
--    savePitchCorrections =  function()
--        elms.pitch_editor:savePitchCorrections()
--    end,
--
--    loadSelectedItems =  function()
--        elms.pitch_editor:setItemsToSelectedItems()
--    end,
--
--    copyPitchCorrections = function()
--        elms.pitch_editor:copySelectedCorrectionNodes()
--    end,
--
--    pastePitchCorrections =  function()
--        elms.pitch_editor:pasteNodes()
--    end,
--
--    applyAllPitchCorrections =  function()
--        elms.pitch_editor:applyPitchCorrections()
--    end,
--
--    openSettingsMenu =  function()
--        elms.pitch_settings:open()
--    end
--}

elms.pitchEditor = {
    type = "PitchEditor",
    z = 3,
    x = 0,
    y = 52,
    w = 0,
    h = 0
}

local knobsX = 10
local knobsY = 25
local knobSize = 22
local knobPadding = 10

elms.modKnob = {
    type = "Knob",
    z = 3,
    x = knobsX,
    y = knobsY,
    w = knobSize,
    h = knobSize,
    min = 0.0,
    max = 1.0,
    default = 20,
    inc = 0.01,
    tooltip = "Mod Correction"
}

elms.driftKnob = {
    type = "Knob",
    z = 3,
    x = knobsX + knobSize + knobPadding,
    y = knobsY,
    w = knobSize,
    h = knobSize,
    min = 0.0,
    max = 1.0,
    default = 100,
    inc = 0.01,
    tooltip = "Drift Correction"
}

elms.menus = {
    type = "Menubar",
    z = 3,
    x = 0,
    y = 0,
    menus = {
        { title = "File",
            options = {
            --    { "Save Pitch Corrections",        menu_functions.savePitchCorrections },
            --    { "Load Selected Items",           menu_functions.loadSelectedItems },
            --    { "Analyze Pitch Content",         menu_functions.analyzePitchGroups },
            --    { "Open Pitch Detection Settings", menu_functions.openSettingsMenu }
            }
        },
        { title = "Edit",
            options = {
            --    { "Copy Pitch Corrections",      menu_functions.copyPitchCorrections },
            --    { "Paste Pitch Corrections",     menu_functions.pastePitchCorrections },
            --    { "Apply All Pitch Corrections", menu_functions.applyAllPitchCorrections }
            }
        },
        --{ title = "View",
        --    options = {
        --        { "Empty",  function() return 0 end }
        --    }
        --},
        --{ title = "Options",
        --    options = {
        --        { "Empty",  function() return 0 end }
        --    }
        --}
    }
}

elms.pitchSettings = {
    type = "Window",
    z = 10,
    x = 1,
    y = 1,
    w = 300,
    h = 300,
    caption = "Pitch Detection Settings",
    z_set = { 9, 10 }
}

--local function createTextboxSetting(title, caption, startingValue, settingNumber)
--    local pdSettingsFont = {fonts.mono, 12}
--
--    local pdSettingsZLayer = 9
--    local pdSettingsXPos = 6
--    local pdSettingsStartingHeight = 6
--    local pdSettingsWidth = 60
--    local pdSettingsHeight = 17
--    local pdSettingsCaptionPadding = 4
--    local pdSettingsVerticalPadding = 1
--
--    local pdSettingsYPos = pdSettingsStartingHeight + (settingNumber - 1) * (pdSettingsVerticalPadding + pdSettingsHeight)
--
--    elms[title] = {
--        type = "Textbox",
--        z = pdSettingsZLayer,
--        x = pdSettingsXPos,
--        y = pdSettingsYPos,
--        w = pdSettingsWidth,
--        h = pdSettingsHeight,
--        caption = caption,
--        pad = pdSettingsCaptionPadding,
--        retval = startingValue,
--        font_b = pdSettingsFont,
--        cap_pos = "right",
--        x_offset = pdSettingsXPos,
--        y_offset = pdSettingsYPos
--    }
--end
--local settingNumber = 1
--createTextboxSetting("windowStep", "Window step (seconds)", pdSettings.windowStep, settingNumber);
--settingNumber = settingNumber + 1;
--createTextboxSetting("overlap", "Overlap", pdSettings.overlap, settingNumber);
--settingNumber = settingNumber + 1;
--createTextboxSetting("minFreq", "Minimum frequency (Hz)", pdSettings.minimumFrequency, settingNumber);
--settingNumber = settingNumber + 1;
--createTextboxSetting("maxFreq", "Maximum frequency (Hz)", pdSettings.maximumFrequency, settingNumber);
--settingNumber = settingNumber + 1;
--createTextboxSetting("YINThresh", "YIN threshold", pdSettings.YINThresh, settingNumber);
--settingNumber = settingNumber + 1;
--createTextboxSetting("lowRMSLimitdB", "Low RMS limit (dB)", pdSettings.lowRMSLimitdB, settingNumber);
--settingNumber = settingNumber + 1;

GUI.elms_hide[10] = true
GUI.elms_hide[9] = true

GUI.CreateElms(elms)

--function elms.pitchSettings:onopen()
--    GUI.elms.windowStep.x = self.x + GUI.elms.windowStep.x_offset
--    GUI.elms.windowStep.y = self.y + self.title_height + GUI.elms.windowStep.y_offset
--    GUI.elms.windowStep:redraw()
--
--    GUI.elms.overlap.x = self.x + GUI.elms.overlap.x_offset
--    GUI.elms.overlap.y = self.y + self.title_height + GUI.elms.overlap.y_offset
--    GUI.elms.overlap:redraw()
--
--    GUI.elms.minFreq.x = self.x + GUI.elms.minFreq.x_offset
--    GUI.elms.minFreq.y = self.y + self.title_height + GUI.elms.minFreq.y_offset
--    GUI.elms.minFreq:redraw()
--
--    GUI.elms.maxFreq.x = self.x + GUI.elms.maxFreq.x_offset
--    GUI.elms.maxFreq.y = self.y + self.title_height + GUI.elms.maxFreq.y_offset
--    GUI.elms.maxFreq:redraw()
--
--    GUI.elms.YINThresh.x = self.x + GUI.elms.YINThresh.x_offset
--    GUI.elms.YINThresh.y = self.y + self.title_height + GUI.elms.YINThresh.y_offset
--    GUI.elms.YINThresh:redraw()
--
--    GUI.elms.lowRMSLimitdB.x = self.x + GUI.elms.lowRMSLimitdB.x_offset
--    GUI.elms.lowRMSLimitdB.y = self.y + self.title_height + GUI.elms.lowRMSLimitdB.y_offset
--    GUI.elms.lowRMSLimitdB:redraw()
--end

--function elms.modKnob:ondrag()
--    GUI.Knob.ondrag(self)
--    changeCorrectionParams()
--    changeCorrectionDefaults()
--end
--
--function elms.modKnob:ondoubleclick()
--    GUI.Knob.ondoubleclick(self)
--    changeCorrectionParams()
--    changeCorrectionDefaults()
--end
--
--function elms.driftKnob:ondrag()
--    GUI.Knob.ondrag(self)
--    changeCorrectionParams()
--    changeCorrectionDefaults()
--end
--
--function elms.driftKnob:ondoubleclick()
--    GUI.Knob.ondoubleclick(self)
--    changeCorrectionParams()
--    changeCorrectionDefaults()
--end
--
--function elms.pitch_editor:selectNode(node)
--    GUI.PitchEditor.selectNode(self, node)
--
--    elms.modKnob:val(node.modCorrection / elms.modKnob.inc)
--    elms.driftKnob:val(node.driftCorrection / elms.driftKnob.inc)
--end

local function mainLoop()
    -- Allow space to play the project.
    if GUI.char == 32 then
        reaper.Main_OnCommandEx(40044, 0, 0)
    end

    -- Update the pitch detection settings that get passed to the editor.
    --pdSettings.windowStep = GUI.elms.windowStep:val()
    --pdSettings.overlap = GUI.elms.overlap:val()
    --pdSettings.minimumFrequency = GUI.elms.minFreq:val()
    --pdSettings.maximumFrequency = GUI.elms.maxFreq:val()
    --pdSettings.YINThresh = GUI.elms.YINThresh:val()
    --pdSettings.lowRMSLimitdB = GUI.elms.lowRMSLimitdB:val()
    --savePitchSettings(pdSettings)

    GUI.save_window_state("Alkamist_PitchCorrection", "windowState")
end

GUI.Init()

GUI.freq = 0
GUI.func = mainLoop

GUI.Main()