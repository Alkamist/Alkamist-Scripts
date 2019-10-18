package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local Alk = require "API.Alkamist API"
local Mouse = require "GFX.Mouse"
local Keys = require "GFX.Keys"

local GFX = {}

GFX.children = GFX.children or {}
GFX.mouse = Mouse:new()
GFX.keys = Keys:new()

function GFX.setColor(color)
    gfx.set(color[1], color[2], color[3], color[4])
end

function GFX.wasResized()
    return GFX.w ~= GFX.prevW or GFX.h ~= GFX.prevH
end

local function updateGFXVariables()
    GFX.prevX = GFX.x or gfx.x
    GFX.prevY = GFX.y or gfx.y
    GFX.prevW = GFX.w or gfx.w
    GFX.prevH = GFX.h or gfx.h

    GFX.char = GFX.keys:getChar()
    GFX.x = gfx.x
    GFX.y = gfx.y
    GFX.w = gfx.w
    GFX.h = gfx.h
end

local function repeatLoop()
    if GFX.char ~= "Escape" and GFX.char ~= "Close" then reaper.defer(GFX.run) end
    gfx.update()
end

local function passThroughPlayKey()
    if GFX.playKey and GFX.char == GFX.playKey then reaper.Main_OnCommandEx(40044, 0, 0) end
end

local function processChildren()
    for _, child in pairs(GFX.children) do
        GFX.focus = GFX.focus or child

        child.relativeMouseX = GFX.mouse:getX() - child.x
        child.relativeMouseY = GFX.mouse:getY() - child.y
        child.prevRelativeMouseX = GFX.mouse:getPrevX() - child.x
        child.prevRelativeMouseY = GFX.mouse:getPrevY() - child.y

        child:onUpdate()

        if GFX.wasResized()                 then child:onResize() end
        if GFX.focus == child and GFX.char  then child:onChar(GFX.char) end

        if child:mouseJustEntered()         then child:onMouseEnter() end
        if child:mouseJustLeft()            then child:onMouseLeave() end

        if child:mouseIsInside() then
            if GFX.mouse.left:justPressed() then
                child._shouldLeftDrag = true
                child:onLeftMouseDown() end
            if GFX.mouse.middle:justPressed() then
                child._shouldMiddleDrag = true
                child:onMiddleMouseDown()
            end
            if GFX.mouse.right:justPressed() then
                child._shouldRightDrag = true
                child:onRightMouseDown()
            end

            if GFX.mouse:getWheel() > 0 or GFX.mouse:getWheel() < 0 then
                child:onMouseWheel(GFX.mouse:getWheel())
            end
            if GFX.mouse:getHWheel() > 0 or GFX.mouse:getHWheel() < 0 then
                child:onMouseHWheel(GFX.mouse:getHWheel())
            end
        end

        local mouseMoved = GFX.mouse:justMoved()
        if mouseMoved and child._shouldLeftDrag then
            child:onLeftMouseDrag()
            child.leftMouseWasDragged = true
        end
        if mouseMoved and child._shouldMiddleDrag then
            child:onMiddleMouseDrag()
            child.middleMouseWasDragged = true
        end
        if mouseMoved and child._shouldRightDrag then
            child:onRightMouseDrag()
            child.rightMouseWasDragged = true
        end

        if GFX.mouse.left:justReleased() then
            child._shouldLeftDrag = false
            child:onLeftMouseUp()
            child.leftMouseWasDragged = false
        end
        if GFX.mouse.middle:justReleased() then
            child._shouldMiddleDrag = false
            child:onMiddleMouseUp()
            child.middleMouseWasDragged = false
        end
        if GFX.mouse.right:justReleased() then
            child._shouldRightDrag = false
            child:onRightMouseUp()
            child.rightMouseWasDragged = false
        end
        child:draw()
    end
end

function GFX.init(title, x, y, w, h, dock)
    gfx.init(title, w, h, dock, x, y)
    GFX.title = title
    GFX.x = x
    GFX.prevX = x
    GFX.y = y
    GFX.prevY = y
    GFX.w = w
    GFX.prevW = w
    GFX.h = h
    GFX.prevH = h
    GFX.dock = 0
end

function GFX.run()
    updateGFXVariables()
    GFX.mouse:update()
    GFX.keys:update()
    passThroughPlayKey()
    if GFX.preHook then GFX.preHook() end
    processChildren()
    if GFX.postHook then GFX.postHook() end
    repeatLoop()
end

return GFX