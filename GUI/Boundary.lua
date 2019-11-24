local reaper = reaper
local pairs = pairs

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GUI = require("GUI.AlkamistGUI")
local mouse = GUI.mouse

local Boundary = {}
function Boundary.new(object)
    local self = {}

    self.x = 0
    self.y = 0
    self.width = 0
    self.height = 0
    self.mouseIsInside = false
    self.mouseWasPreviouslyInside = false
    self.mouseJustEntered = false
    self.mouseJustLeft = false

    local object = object or {}
    for k, v in pairs(self) do if object[k] == nil then object[k] = v end end
    return object
end

function Boundary.pointIsInside(self, pointX, pointY)
    local x, y, w, h = self.x, self.y, self.width, self.height
    return pointX >= x and pointX <= x + w
       and pointY >= y and pointY <= y + h
end
function Boundary.update(self)
    self.mouseIsInside = Boundary.pointIsInside(self, mouse.x, mouse.y)
    self.mouseJustEntered = self.mouseIsInside and not self.mouseWasPreviouslyInside
    self.mouseJustLeft = not self.mouseIsInside and self.mouseWasPreviouslyInside
end
function Boundary.endUpdate(self)
    self.mouseWasPreviouslyInside = self.mouseIsInside
end

return Boundary