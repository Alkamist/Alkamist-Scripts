package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local lib_path = reaper.GetExtState("Lokasenna_GUI", "lib_path_v2")
if not lib_path or lib_path == "" then
    reaper.MB("Couldn't load the Lokasenna_GUI library. Please run 'Script: Set Lokasenna_GUI v2 library path.lua' in your Action List.", "Whoops!", 0)
    return
end
loadfile(lib_path .. "Core.lua")()

require "Pitch Correction.GUI.Class - PitchEditor"
GUI.req("Classes/Class - Button.lua")()
GUI.req("Classes/Class - Tabs.lua")()
GUI.req("Classes/Class - Textbox.lua")()
GUI.req("Classes/Class - Menubar.lua")()
GUI.req("Classes/Class - Knob.lua")()

-- If any of the requested libraries weren't found, abort the script.
if missing_lib then return 0 end



-- Pitch detection settings:
local pdSettings = {}
pdSettings.windowStep = 0.04
pdSettings.overlap = 2.0
pdSettings.minimumFrequency = 80
pdSettings.maximumFrequency = 500
pdSettings.YINThresh = 0.2
pdSettings.lowRMSLimitdB = -60



local guiDock, guiX, guiY, guiW, guiH = GUI.load_window_state("Alkamist_PitchCorrection", "windowState")

GUI.name = "Alkamist Pitch Correction"
GUI.dock = tonumber(guiDock) or 0
GUI.x = tonumber(guiX) or 500
GUI.y = tonumber(guiY) or 100
GUI.w = tonumber(guiW) or 1200
GUI.h = tonumber(guiH) or 700



local fonts = GUI.get_OS_fonts()

local elms = {}



local menu_functions = {

    analyzePitchGroups = function()
        elms.pitch_editor:analyzePitchGroups()
    end,

    savePitchCorrections =  function()
        elms.pitch_editor:savePitchCorrections()
    end,

    loadSelectedItems =  function()
        elms.pitch_editor:setItemsToSelectedItems()
    end,

    copyPitchCorrections = function()
        elms.pitch_editor:copySelectedCorrectionNodes()
    end,

    pastePitchCorrections =  function()
        elms.pitch_editor:pasteNodes()
    end,

    applyAllPitchCorrections =  function()
        elms.pitch_editor:applyPitchCorrections()
    end

}



elms.pitch_editor = {
    type = "PitchEditor",
    z = 3,
    x = 0,
    y = 52,
    w = 0,
    h = 0,
    pdSettings = pdSettings
}

local knobsX = 10
local knobsY = 25
local knobSize = 22
local knobPadding = 10

elms.mod_knob = {
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

elms.drift_knob = {
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
                { "Save Pitch Corrections",  menu_functions.savePitchCorrections },
                { "Load Selected Items",     menu_functions.loadSelectedItems },
                { "Analyze Pitch Content",   menu_functions.analyzePitchGroups }
            }
        },

        { title = "Edit",

            options = {
                { "Copy Pitch Corrections",  menu_functions.copyPitchCorrections },
                { "Paste Pitch Corrections", menu_functions.pastePitchCorrections },
                { "Apply All Pitch Corrections", menu_functions.applyAllPitchCorrections }
            }
        },

        { title = "View",

            options = {
                { "Empty",  function() return 0 end }
            }
        },

        { title = "Options",

            options = {
                { "Empty",  function() return 0 end }
            }
        }
    }
}



GUI.CreateElms(elms)



local function changeCorrectionParams()
    local params = {
        modCorrection = elms.mod_knob:val(),
        driftCorrection = elms.drift_knob:val()
    }

    elms.pitch_editor:changeSelectedNodesParams(params)
end

local function changeCorrectionDefaults()
    elms.pitch_editor.correctionGroup.defaults.modCorrection = elms.mod_knob:val()
    elms.pitch_editor.correctionGroup.defaults.driftCorrection = elms.drift_knob:val()
end

function elms.mod_knob:ondrag()
    GUI.Knob.ondrag(self)
    changeCorrectionParams()
    changeCorrectionDefaults()
end

function elms.mod_knob:ondoubleclick()
    GUI.Knob.ondoubleclick(self)
    changeCorrectionParams()
    changeCorrectionDefaults()
end

function elms.drift_knob:ondrag()
    GUI.Knob.ondrag(self)
    changeCorrectionParams()
    changeCorrectionDefaults()
end

function elms.drift_knob:ondoubleclick()
    GUI.Knob.ondoubleclick(self)
    changeCorrectionParams()
    changeCorrectionDefaults()
end


function elms.pitch_editor:selectNode(node)
    GUI.PitchEditor.selectNode(self, node)

    elms.mod_knob:val(node.modCorrection / elms.mod_knob.inc)
    elms.drift_knob:val(node.driftCorrection / elms.drift_knob.inc)
end


local function mainLoop()
    -- Allow space to play the project.
    if GUI.char == 32 then
        reaper.Main_OnCommandEx(40044, 0, 0)
    end

    GUI.save_window_state("Alkamist_PitchCorrection", "windowState")
end

GUI.Init()

GUI.freq = 0
GUI.func = mainLoop

GUI.Main()