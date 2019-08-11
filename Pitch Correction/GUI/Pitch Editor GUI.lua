package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Script: Set Lokasenna_GUI v2 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

local PCFunc = require "Pitch Correction.Helper Functions.Pitch Correction Functions"

require "Pitch Correction.GUI.Class - PitchEditor"
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Textbox.lua")()

-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end



-- Pitch detection settings:
local pdSettings = {}
pdSettings.maximumLength = 300
pdSettings.windowStep = 0.04
pdSettings.overlap = 2.0
pdSettings.minimumFrequency = 60
pdSettings.maximumFrequency = 500
pdSettings.YINThresh = 0.2
pdSettings.lowRMSLimitdB = -60



local guiWidth = 1200
local guiHeight = 700

GUI.name = "Alkamist Pitch Correction"
GUI.x, GUI.y = 500, 100
GUI.w, GUI.h = guiWidth, guiHeight

local fonts = GUI.get_OS_fonts()

local elms = {}

local function analyze_button_click()
    local selectedTake = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))

    PCFunc.saveSettingsInExtState(pdSettings)
    PCFunc.analyzePitch(selectedTake)

    elms.pitch_editor:setTake(selectedTake, pdSettings)
end



elms.tabs = {
    type = "Tabs",
    z = 20,
    x = 0,
    y = 0,
    tab_w = 64,
    tab_h = 20,
    opts = "Editor,Options",
    pad = 16
}

GUI.colors["analyze_button"] = {155, 32, 32, 255}
elms.analyze_button = {
    type = "Button",
    z = 3,
    x = 2,
    y = 22,
    w = 64,
    h = 24,
    col_fill = "analyze_button",
    caption = "Analyze",
    func = analyze_button_click,
    tooltip = "Analyzes the selected audio to get pitch info."
}

elms.pitch_editor = {
    type = "PitchEditor",
    z = 3,
    x = 2,
    y = 52,
    w = 0,
    h = 0,
    take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0)),
    pdSettings = pdSettings
}



-------------- Settings: --------------

local function createTextboxSetting(title, caption, startingValue, settingNumber)
    local pdSettingsFont = {fonts.mono, 12}

    local pdSettingsZLayer = 4
    local pdSettingsXPos = 170
    local pdSettingsStartingHeight = 25
    local pdSettingsWidth = 60
    local pdSettingsHeight = 17
    local pdSettingsCaptionPadding = 4
    local pdSettingsVerticalPadding = 1

    local pdSettingsYPos = pdSettingsStartingHeight + (settingNumber - 1) * (pdSettingsVerticalPadding + pdSettingsHeight)

    elms[title] = {
        type = "Textbox",
        z = pdSettingsZLayer,
        x = pdSettingsXPos,
        y = pdSettingsYPos,
        w = pdSettingsWidth,
        h = pdSettingsHeight,
        caption = caption,
        pad = pdSettingsCaptionPadding,
        retval = startingValue,
        font_b = pdSettingsFont
    }
end

local settingNumber = 1
createTextboxSetting("maxLength", "Max item length (seconds):", 59, settingNumber);
settingNumber = settingNumber + 1;

createTextboxSetting("windowStep", "Window step (seconds):", 59, settingNumber);
settingNumber = settingNumber + 1;

createTextboxSetting("overlap", "Overlap:", 59, settingNumber);
settingNumber = settingNumber + 1;

createTextboxSetting("minFreq", "Minimum frequency (Hz):", 59, settingNumber);
settingNumber = settingNumber + 1;

createTextboxSetting("maxFreq", "Maximum frequency (Hz):", 59, settingNumber);
settingNumber = settingNumber + 1;

createTextboxSetting("YINThresh", "YIN threshold:", 59, settingNumber);
settingNumber = settingNumber + 1;

createTextboxSetting("lowRMSLimitdB", "Low RMS limit (dB):", 59, settingNumber);
settingNumber = settingNumber + 1;



GUI.CreateElms(elms)

local previousSelectedItem = nil
local function mainLoop()
    -- Allow space to play the project.
    if GUI.char == 32 then
        reaper.Main_OnCommandEx(40044, 0, 0)
    end
end

GUI.elms.tabs:update_sets(
    --  Tab     Layers
    {   [1] =   {3},
        [2] =   {4},
    }
)

GUI.Init()

GUI.freq = 0
GUI.func = mainLoop

GUI.Main()