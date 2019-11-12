function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
--local GUI = require("GUI.AlkamistGUI")
--local Button = require("GUI.Button")
--local BoxSelect = require("GUI.BoxSelect")

local Prototype = require("Prototype")

local TestProto = Prototype:new{
    asdfout = "yee",
    asdf = function(self) msg(self.asdfout) end
}

local Test = Prototype:new{
    --initialize = function(self) msg("yeyeyeye") end,
    prototypes = {
        { "testProto", TestProto:new() }
    },
    --testProto = TestProto:new(),
    --asdfout = { from = { "testProto", "asdfout" } },
    --asdf = { from = { "testProto", "asdf" } },

    a = {
        x = 1,
        y = 2
    },
    b = {
        from = { "a", "x" },
        get = function(self, value) msg("getb") end,
        set = function(self, value) msg("setb") end,
    },
    c = {
        from = "b",
        get = function(self, value) msg("getc") end,
        set = function(self, value) msg("setc") end,
    },
    d = {
        from = "c",
        get = function(self, value) msg("getd") end,
        set = function(self, value) msg("setd") end,
    },
--    c = {
--        get = function(self) return self.b end,
--        set = function(self, value) self.b = value end
--    },
--    d = {
--        get = function(self) return self.c end,
--        set = function(self, value) self.c = value end
--    }
}

local test1 = Test:new()
--local test2 = Test:new()

--msg(test1.a)
--msg(test1.b)
--msg(test1.c)
--msg(test1.b)
--test1.b = 7
--msg(test1.b)

msg(test1.asdfout)
test1:asdf()


--msg(test1.a.x)
--msg(test1.b)
--msg(test1.c)
--msg(test1.d)

--msg(test1.a)
--msg(test1.b)
--msg(test1.c)
--msg(test1.d)
--msg("")
--
--test1.c = 2
--
--msg(test1.a)
--msg(test1.b)
--msg(test1.c)
--msg(test1.d)

--for k, v in pairs(test1) do
--    msg(k)
--    msg(v)
--end

--GUI:initialize{
--    title = "Alkamist Pitch Correction",
--    x = 200,
--    y = 200,
--    width = 1000,
--    height = 700,
--    dock = 0
--}
--GUI.backgroundColor = { 0.2, 0.2, 0.2 }
--GUI:run()

--local testButton1 = Button{
--    GUI = GUI,
--    x = 80,
--    y = 200,
--    width = 400,
--    height = 400,
--    label = "Fix Errors",
--    --toggleOnClick = true
--}
--
--function testButton1:update()
--    originalTestButton1Update()
--    local mouse = GUI:getMouse()
--    local mouseLeftButton = mouse:getButtons().left
--    if mouseLeftButton:justDragged(testButton1) then
--        testButton1.x = testButton1.x + mouse:getXChange()
--        testButton1.y = testButton1.y + mouse:getYChange()
--    end
--end

--[[local thingsToSelect = {
    testButton1
}
local function isInsideFunction(box, thing)
    return box:pointIsInside(thing:getX(), thing:getY())
end
local function setSelectedFunction(thing, shouldSelect)
    if shouldSelect then
        thing:press()
    else
        thing:release()
    end
end
local function getSelectedFunction(thing)
    return thing:isPressed()
end

local boxSelect = BoxSelect{ GUI = GUI }

function boxSelect.update()
    local mouse = GUI:getMouse()
    local mouseRightButton = mouse:getButtons().right
    local mouseX = mouse:getX()
    local mouseY = mouse:getY()
    local keyboardModifiers = GUI:getKeyboard():getModifiers()

    if mouseRightButton:justPressed() then
        boxSelect:startSelection(mouseX, mouseY)
    end

    if mouseRightButton:justDragged() then
        boxSelect:editSelection(mouseX, mouseY)
    end

    if mouseRightButton:justReleased() then
        boxSelect:makeSelection{
            thingsToSelect = thingsToSelect,
            isInsideFunction = isInsideFunction,
            setSelectedFunction = setSelectedFunction,
            getSelectedFunction = getSelectedFunction,
            shouldAdd = keyboardModifiers.shift:isPressed(),
            shouldInvert = keyboardModifiers.control:isPressed()
        }
    end
end]]--

--GUI:addWidgets{ testButton1, boxSelect }
--GUI:addWidgets{ testButton1 }
--GUI:run()