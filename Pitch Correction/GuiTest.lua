function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require("GFX.Alkamist GFX")
local Button = require("GFX.Button")

GFX:init("Alkamist Pitch Correction", 200, 200, 1000, 700, 0)

local pitchEditor = require("Pitch Correction.PitchEditor"):new{
    x = 200,
    y = 200,
    w = 600,
    h = 300
}

local testButton1 = Button:new{
    x = 40,
    y = 40,
    w = 120,
    h = 25
}
function testButton1:onMouseLeftDown()
    Button.onMouseLeftDown(self)
    self:setFocus(true)
    --if pitchEditor.isVisible then
    --    pitchEditor:hide()
    --else
    --    pitchEditor:show()
    --end
end
function testButton1:onMouseLeftDrag()
    self.x = self.x + self.GFX.mouseXChange
    self.y = self.y + self.GFX.mouseYChange
end


local testButton2 = Button:new{
    x = 20,
    y = 20,
    w = 120,
    h = 25
}
table.insert(pitchEditor.elements, testButton2)

GFX:setBackgroundColor{ 0.2, 0.2, 0.2 }
--GFX:setElements{ pitchEditor }
GFX:setElements{ pitchEditor, testButton1 }
GFX:run()