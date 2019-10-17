package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local GFX = require "GFX.Alkamist GFX"
local GFXChild = require "GFX.GFXChild"

local BoxSelect = setmetatable({}, { __index = GFXChild })
function BoxSelect:new(object)
    local object = object or {}
    object._base = self
    self.init(object)
    return object
end

function BoxSelect:init()
    GFXChild.init(self)
    self.__index = self._base
    setmetatable(self, self)
end

---------------------- Drawing Code ----------------------



---------------------- Events ----------------------

function BoxSelect:onUpdate() end
function BoxSelect:onResize() end
function BoxSelect:onChar(char) end
function BoxSelect:onMouseEnter() end
function BoxSelect:onMouseLeave() end
function BoxSelect:onLeftMouseDown() end
function BoxSelect:onLeftMouseUp() end
function BoxSelect:onLeftMouseDrag() end
function BoxSelect:onMiddleMouseDown() end
function BoxSelect:onMiddleMouseUp() end
function BoxSelect:onMiddleMouseDrag() end
function BoxSelect:onRightMouseDown() end
function BoxSelect:onRightMouseUp() end
function BoxSelect:onRightMouseDrag() end
function BoxSelect:onMouseWheel(numTicks) end
function BoxSelect:onMouseHWheel(numTicks) end
function BoxSelect:draw() end

return BoxSelect