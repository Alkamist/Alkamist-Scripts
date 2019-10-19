package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Mouse = require("GFX.Mouse")
local Keyboard = require("GFX.Keyboard")

local AlkamistGFX = {}

function AlkamistGFX:new(init)
    local init = init or {}
    local title = init.title or ""
    local width = init.width or 0
    local height = init.height or 0
    local x = init.x or 0
    local y = init.y or 0
    local dock = init.dock or 0

    gfx.init(title, width, height, dock, x, y)

    local self = setmetatable({}, { __index = self })

    self._title = title
    self._x = x
    self._previousX = x
    self._y = y
    self._previousY = y
    self._width = width
    self._previousWidth = width
    self._height = height
    self._previousHeight = height
    self._dock = dock
    self._playKey = nil
    self._preHookFn = nil
    self._postHookFn = nil
    self._focus = nil
    self._children = {}
    self._mouse = Mouse:new()
    self._keyboard = Keyboard:new()

    return self
end

function AlkamistGFX:getTitle()              return self._title end
function AlkamistGFX:getX()                  return self._x end
function AlkamistGFX:getY()                  return self._y end
function AlkamistGFX:getWidth()              return self._width end
function AlkamistGFX:getPreviousWidth()      return self._previousWidth end
function AlkamistGFX:getWidthChange()        return self:getWidth() - self:getPreviousWidth() end
function AlkamistGFX:getHeight()             return self._height end
function AlkamistGFX:getPreviousHeight()     return self._previousHeight end
function AlkamistGFX:getHeightChange()       return self:getHeight() - self:getPreviousHeight() end
function AlkamistGFX:windowWasResized(color)
    return self:getWidth() ~= self:getPreviousWidth() or self:getHeight() ~= self:getPreviousHeight()
end
function AlkamistGFX:getMouse()              return self._mouse end
function AlkamistGFX:getKeyboard()           return self._keyboard end
function AlkamistGFX:getChildren()           return self._children end
function AlkamistGFX:getPlayKey()            return self._playKey end
function AlkamistGFX:getFocus()              return self._focus end

function AlkamistGFX:setColor(color)         gfx.set(color[1], color[2], color[3], color[4]) end
function AlkamistGFX:setPlayKey(playKey)     self._playKey = playKey end
function AlkamistGFX:setFocus(focus)         self._focus = focus end
function AlkamistGFX:setChildren(children)   self._children = children end
function AlkamistGFX:setPreHook(fn)          self._preHookFn = fn end
function AlkamistGFX:setPostHook(fn)         self._postHookFn = fn end

function AlkamistGFX:processChildren()
    local keyboard = self:getKeyboard()
    local char = keyboard:getChar()
    local mouse = self:getMouse()
    local mouseMoved = mouse:justMoved()
    local leftClick = mouse:getButtons().left
    local middleClick = mouse:getButtons().middle
    local rightClick = mouse:getButtons().right
    local wheel = self:getMouse():getWheel()
    local wheelMoved = wheel > 0 or wheel < 0
    local hWheel = self:getMouse():getHWheel()
    local hWheelMoved = hWheel > 0 or hWheel < 0

    for _, child in pairs(self:getChildren()) do
        self:setFocus(self:getFocus() or child)

        child:onUpdate()

        if GFX.windowWasResized()            then child:onResize() end
        if self:getFocus() == child and char then child:onChar(char) end

        if child:mouseJustEntered()          then child:onMouseEnter() end
        if child:mouseJustLeft()             then child:onMouseLeave() end

        if child:mouseIsInside() then
            if leftClick:justPressed() then
                child:setLeftDrag(true)
                child:onMouseLeftButtonDown()
            end
            if middleClick:justPressed() then
                child:setMiddleDrag(true)
                child:onMouseMiddleButtonDown()
            end
            if rightClick:justPressed() then
                child:setRightDrag(true)
                child:onMouseRightButtonDown()
            end

            if wheelMoved then child:onMouseWheel(wheel) end
            if hWheelMoved then child:onMouseHWheel(hWheel) end
        end

        if mouseMoved and child:isLeftDragging() then   child:onMouseLeftButtonDrag() end
        if mouseMoved and child:isMiddleDragging() then child:onMouseMiddleButtonDrag() end
        if mouseMoved and child:isRightDragging() then  child:onMouseRightButtonDrag() end

        if leftClick:justReleased() then
            child:onMouseLeftButtonUp()
            child:setLeftDrag(false)
        end
        if middleClick:justReleased() then
            child:onMouseMiddleButtonUp()
            child:setMiddleDrag(false)
        end
        if rightClick:justReleased() then
            child:onMouseRightButtonUp()
            child:setRightDrag(false)
        end

        child:onDraw()
    end
end

function AlkamistGFX:updateGFXVariables()
    self._previousX =      self._x
    self._previousY =      self._y
    self._previousWidth =  self._width
    self._previousHeight = self._height
    self._x =              gfx.x
    self._y =              gfx.y
    self._width =          gfx.w
    self._height =         gfx.h
end
function AlkamistGFX:passThroughPlayKey()
    local keyboard = self:getKeyboard()
    local char = keyboard:getChar()
    local playKey = self:getPlayKey()
    if playKey and char == playKey then reaper.Main_OnCommandEx(40044, 0, 0) end
end
function AlkamistGFX:flagLoopForRepeat()
    local keyboard = self:getKeyboard()
    local char = keyboard:getChar()
    if char ~= "Escape" and char ~= "Close" then reaper.defer(self.run) end
    gfx.update()
end
function AlkamistGFX:run()
    self:updateGFXVariables()
    self:getMouse():update()
    self:getKeyboard():update()
    self:passThroughPlayKey()
    if self._preHookFn then self._preHookFn() end
    self:processChildren()
    if self._postHookFn then self._postHookFn() end
    self:flagLoopForRepeat()
end

return AlkamistGFX