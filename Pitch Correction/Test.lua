function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

--package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local function Fighter(fields)
    local self = fields or {}
    self.strength = 1
    function self:getStrength() return self.strength end
    return self
end

local function Writer(fields)
    local self = fields or {}
    self.strength = "horror"
    function self:sayStrength() return self.strength end
    return self
end

local test = Writer(Fighter())

msg(test.strength)