package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\?.lua;" .. package.path
local NumberTracker = require("Logic.NumberTracker")
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

    self.title =    title
    self.x =        NumberTracker:new(x)
    self.y =        NumberTracker:new(y)
    self.width =    NumberTracker:new(width)
    self.height =   NumberTracker:new(height)
    self.dock =     NumberTracker:new(dock)
    self.mouse =    Mouse:new()
    self.keyboard = Keyboard:new()
    self.playKey = nil
    self.preHookFn = nil
    self.postHookFn = nil
    self.focus = nil
    self.children = {}
end

function AlkamistGFX:setPlayKey(playKey) self.playKey = playKey end
function AlkamistGFX:setChildren(children)
    self.children = children

    for _, child in pairs(self.children) do
        child.GFX =      self
        child.mouse =    self.mouse
        child.keyboard = self.keyboard
    end
end

function AlkamistGFX:processChildren()
    local state = {
        x = self.x,
        y = self.y,
        width = self.width,
        height = self.height
    }

    for _, child in pairs(self.children) do
        self.focus = self.focus or child

        child:updateState(state)
        child:onUpdate()

        if self.width.value.changed or self.height.value.changed then
            child:onResize()
        end
        if self.focus == child and self.keyboard.char then
            child:onKeyPress()
        end

        if child:mouseJustEntered() then child:onMouseEnter() end
        if child:mouseJustLeft()    then child:onMouseLeave() end

        if child:mouseIsInside() then
            if self.mouse.buttons.left.switch.activated then
                child.leftDragIsEnabled = true
                child:onMouseLeftButtonDown()
            end
            if self.mouse.buttons.middle.switch.activated then
                child.middleDragIsEnabled = true
                child:onMouseMiddleButtonDown()
            end
            if self.mouse.buttons.right.switch.activated then
                child.rightDragIsEnabled = true
                child:onMouseRightButtonDown()
            end

            if self.mouse.wheel.changed  then child:onMouseWheel() end
            if self.mouse.hWheel.changed then child:onMouseHWheel() end
        end

        if self.mouse.moved and child.leftDragIsEnabled then
            child.leftIsDragging = true
            child:onMouseLeftButtonDrag()
        end
        if self.mouse.moved and child.middleDragIsEnabled then
            child.middleIsDragging = true
            child:onMouseMiddleButtonDrag()
        end
        if self.mouse.moved and child.rightDragIsEnabled then
            child.rightIsDragging = true
            child:onMouseRightButtonDrag()
        end

        if self.mouse.buttons.left.switch.deactivated then
            child:onMouseLeftButtonUp()
            child.leftIsDragging = false
            child.leftDragIsEnabled = false
        end
        if self.mouse.buttons.middle.switch.deactivated then
            child:onMouseMiddleButtonUp()
            child.middleIsDragging = false
            child.middleDragIsEnabled = false
        end
        if self.mouse.buttons.right.switch.deactivated then
            child:onMouseRightButtonUp()
            child.rightIsDragging = false
            child.rightDragIsEnabled = false
        end

        child:onDraw()
    end
end

function AlkamistGFX.run()
    local self = AlkamistGFX

    -- Update the gfx parameters.
    self.x:update(gfx.x)
    self.y:update(gfx.y)
    self.width:update(gfx.w)
    self.height:update(gfx.h)
    self.mouse:update()
    self.keyboard:update()

    -- Pass through the play key.
    if self.playKey and self.keyboard.char == self.playKey then
        reaper.Main_OnCommandEx(40044, 0, 0)
    end

    if self.preHookFn then
        self.preHookFn()
    end

    self:processChildren()

    if self.postHookFn then
        self.postHookFn()
    end

    -- Flag the run loop to repeat.
    if self.keyboard.char ~= "Escape" and self.keyboard.char ~= "Close" then
        reaper.defer(self.run)
    end
    gfx.update()
end

return AlkamistGFX