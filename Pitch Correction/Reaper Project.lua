package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local ReaperPointerWrapper = require "Pitch Correction.Reaper Pointer Wrapper"

local Project = setmetatable({}, { __index = ReaperPointerWrapper })
function Project:new(object)
    local object = object or {}
    setmetatable(object, { __index = self })
    object:init()
    return object
end

function Project:init()
    self.pointerType = "MediaItem_Take*"
    ReaperPointerWrapper.init(self)
end