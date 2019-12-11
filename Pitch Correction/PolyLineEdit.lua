local GUI = require("GUI")

local math = math
local sqrt = math.sqrt
local table = table
local tableInsert = table.insert

local PolyLineEdit = {}

function PolyLineEdit:requires()
    return self.PolyLineEdit
end
function PolyLineEdit:getDefaults()
    local defaults = {}
    defaults.points = {}
    defaults.mouseOverIndex = nil
    defaults.mouseIsOverPoint = nil
    defaults.editPoint = nil
    return defaults
end
function PolyLineEdit:update()
    local points = self.points

    if GUI.leftMouseButtonJustPressed and self.mouseOverIndex then

    end

    for i = 1, #points do
        local point = points[i]
    end
end

return PolyLineEdit