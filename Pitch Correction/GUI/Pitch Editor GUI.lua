package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Script: Set Lokasenna_GUI v2 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

require "Helper Functions.Pitch Correction Functions"
require "GUI.Class - PitchEditor"
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Textbox.lua")()

-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end



-- Pitch detection settings:
local settings = {}
settings.maximumLength = 300
settings.windowStep = 0.04
settings.overlap = 2.0
settings.minimumFrequency = 60
settings.maximumFrequency = 1000
settings.YINThresh = 0.2
settings.lowRMSLimitdB = -60



local guiWidth = 1000
local guiHeight = 800

GUI.name = "Alkamist Pitch Correction"
GUI.x, GUI.y = 500, 100
GUI.w, GUI.h = guiWidth, guiHeight

local fonts = GUI.get_OS_fonts()

local elms = {}

local function analyze_button_click()
    local selectedTake = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))

    saveSettingsInExtState(settings)
    analyzePitch(selectedTake)

    elms.pitch_editor:setTake(selectedTake)
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
    take = reaper.GetActiveTake(reaper.GetSelectedMediaItem(0, 0))
}


-------------- Settings: --------------

local function createTextboxSetting(title, caption, startingValue, settingNumber)
    local settingsFont = {fonts.mono, 12}

    local settingsZLayer = 4
    local settingsXPos = 170
    local settingsStartingHeight = 25
    local settingsWidth = 60
    local settingsHeight = 17
    local settingsCaptionPadding = 4
    local settingsVerticalPadding = 1

    local settingsYPos = settingsStartingHeight + (settingNumber - 1) * (settingsVerticalPadding + settingsHeight)

    elms[title] = {
        type = "Textbox",
        z = settingsZLayer,
        x = settingsXPos,
        y = settingsYPos,
        w = settingsWidth,
        h = settingsHeight,
        caption = caption,
        pad = settingsCaptionPadding,
        retval = startingValue,
        font_b = settingsFont
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
    local selectedItem = reaper.GetSelectedMediaItem(0, 0)

    if selectedItem ~= previousSelectedItem then
        local selectedTake = reaper.GetActiveTake(selectedItem)
        elms.pitch_editor:setTake(selectedTake)
    end

    previousSelectedItem = selectedItem
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