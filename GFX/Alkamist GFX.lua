package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path

local Mouse = require("GFX.Mouse")
local Keyboard = require("GFX.Keyboard")

local AlkamistGFX = {}

function AlkamistGFX:init(init)
    local init = init or {}
    local title = init.title or ""
    local width = init.width or 0
    local height = init.height or 0
    local x = init.x or 0
    local y = init.y or 0
    local dock = init.dock or 0

    gfx.init(title, width, height, dock, x, y)

    self.title = title
    self.x = x
    self.previousX = x
    self.y = y
    self.previousY = y
    self.width = width
    self.previousWidth = width
    self.height = height
    self.previousHeight = height
    self.dock = dock
    self.playKey = nil
    self.preHookFn = nil
    self.postHookFn = nil
    self.focus = nil
    self.children = {}
    self.mouse = Mouse:new()
    self.keyboard = Keyboard:new()
end

function AlkamistGFX:getTitle()              return self.title end
function AlkamistGFX:getX()                  return self.x end
function AlkamistGFX:getY()                  return self.y end
function AlkamistGFX:getWidth()              return self.width end
function AlkamistGFX:getPreviousWidth()      return self.previousWidth end
function AlkamistGFX:getWidthChange()        return self:getWidth() - self:getPreviousWidth() end
function AlkamistGFX:getHeight()             return self.height end
function AlkamistGFX:getPreviousHeight()     return self.previousHeight end
function AlkamistGFX:getHeightChange()       return self:getHeight() - self:getPreviousHeight() end
function AlkamistGFX:windowWasResized()
    return self:getWidth() ~= self:getPreviousWidth() or self:getHeight() ~= self:getPreviousHeight()
end
function AlkamistGFX:getMouse()              return self.mouse end
function AlkamistGFX:getKeyboard()           return self.keyboard end
function AlkamistGFX:getChildren()           return self.children end
function AlkamistGFX:getPlayKey()            return self.playKey end
function AlkamistGFX:getFocus()              return self.focus end

function AlkamistGFX:setColor(color)         gfx.set(color[1], color[2], color[3], color[4]) end
function AlkamistGFX:setPlayKey(playKey)     self.playKey = playKey end
function AlkamistGFX:setFocus(focus)         self.focus = focus end
function AlkamistGFX:setChildren(children)   self.children = children end
function AlkamistGFX:setPreHook(fn)          self.preHookFn = fn end
function AlkamistGFX:setPostHook(fn)         self.postHookFn = fn end

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
    local children = self:getChildren()

    for _, child in pairs(children) do
        self:setFocus(self:getFocus() or child)

        child:onUpdate()

        if self:windowWasResized()           then child:onResize() end
        if self:getFocus() == child and char then child:onChar(char) end

        if child:mouseJustEntered()          then child:onMouseEnter() end
        if child:mouseJustLeft()             then child:onMouseLeave() end

        if child:mouseIsInside() then
            if leftClick:justPressed() then
                child:enableLeftDrag(true)
                child:onMouseLeftButtonDown()
            end
            if middleClick:justPressed() then
                child:enableMiddleDrag(true)
                child:onMouseMiddleButtonDown()
            end
            if rightClick:justPressed() then
                child:enableRightDrag(true)
                child:onMouseRightButtonDown()
            end

            if wheelMoved then child:onMouseWheel(wheel) end
            if hWheelMoved then child:onMouseHWheel(hWheel) end
        end

        if mouseMoved and child:isLeftDragEnabled() then
            child:markAsLeftDragging(true)
            child:onMouseLeftButtonDrag()
        end
        if mouseMoved and child:isMiddleDragEnabled() then
            child:markAsMiddleDragging(true)
            child:onMouseMiddleButtonDrag()
        end
        if mouseMoved and child:isRightDragEnabled() then
            child:markAsRightDragging(true)
            child:onMouseRightButtonDrag()
        end

        if leftClick:justReleased() then
            child:onMouseLeftButtonUp()
            child:enableLeftDrag(false)
            child:markAsLeftDragging(false)
        end
        if middleClick:justReleased() then
            child:onMouseMiddleButtonUp()
            child:enableMiddleDrag(false)
            child:markAsMiddleDragging(false)
        end
        if rightClick:justReleased() then
            child:onMouseRightButtonUp()
            child:enableRightDrag(false)
            child:markAsRightDragging(false)
        end

        child:onDraw()
    end
end
function AlkamistGFX:updateGFXVariables()
    self.previousX =      self.x
    self.previousY =      self.y
    self.previousWidth =  self.width
    self.previousHeight = self.height
    self.x =              gfx.x
    self.y =              gfx.y
    self.width =          gfx.w
    self.height =         gfx.h
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
function AlkamistGFX.run()
    local self = AlkamistGFX

    self:updateGFXVariables()
    self:getMouse():update()
    self:getKeyboard():update()
    self:passThroughPlayKey()
    if self.preHookFn then self.preHookFn() end
    self:processChildren()
    if self.postHookFn then self.postHookFn() end
    self:flagLoopForRepeat()
end

return AlkamistGFX