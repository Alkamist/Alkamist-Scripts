function msg(m) reaper.ShowConsoleMsg(tostring(m) .. "\n") end

package.path = reaper.GetResourcePath() .. package.config:sub(1,1) .. "Scripts\\Alkamist Scripts\\Pitch Correction\\?.lua;" .. package.path
local Fn = require("Fn")

local function createProxy(object)
    local object = object or {}
    local properties = {}

    function object:addProperty(name, property)
        object[name] = nil
        if type(property) == "table" then
            properties[name] = property
        end
    end

    return setmetatable(object, {
        __index = function(t, k)
            local propertyGet = properties[k].get
            if propertyGet then
                return propertyGet(t)
            end
        end,
        __newindex = function(t, k, v)
            local propertySet = properties[k]
            if propertySet then
                return propertySet(t, v)
            end
        end,
        __pairs = function(t)
            return function(t, k)
                local fieldKey = next(properties, k)
                return fieldKey, t[fieldKey]
            end, t, nil
        end
    })
end

local test1 = createProxy{
    a = 1
}
test1:addProperty("b", {
    get = function(self) return 123123123 end,
    set = function(self, v) end
})

for k, v in pairs(test1) do msg(k) end

--msg(test1.a)
--test1.a = 5
--msg(test1.a)
--
--test1:addProperty("a", {
--    get = function(self) return 123123123 end,
--    set = function(self, v) end
--})
--
--msg(test1.a)
--test1.a = 5
--msg(test1.a)

--local timer = reaper.time_precise()
--for i = 1, 1000000 do
--    test1.a = 0
--    local asdf = test1.a
--end
--msg(reaper.time_precise() - timer)
--
--local test2 = { a = 0 }
--
--local timer = reaper.time_precise()
--for i = 1, 1000000 do
--    test2.a = 0
--    local asdf = test2.a
--end
--msg(reaper.time_precise() - timer)







--local GUI = require("GUI")
--local PolyLine = require("PolyLine")
--local Image = require("Image")
--local Button = require("Button")
--local BoxSelect = require("BoxSelect")
--
--GUI.initialize{
--    title = "Alkamist Pitch Correction",
--    x = 400,
--    y = 200,
--    width = 1000,
--    height = 700,
--    dock = 0
--}
--GUI.window.setBackgroundColor(0.2, 0.2, 0.2)
--
--local button = Button.new{
--    x = 5,
--    y = 5,
--    width = 30,
--    height = 30,
--    label = "1"
--}
--local button2 = Button.new{
--    x = 5,
--    y = 5,
--    width = 30,
--    height = 30,
--    label = "2"
--}
--local image = Image.new{
--    x = 100,
--    y = 100,
--    width = 200,
--    height = 200,
--    backgroundColor = { 0.2, 0.5, 0.7 }
--}
--local image2 = Image.new{
--    x = 100,
--    y = 100,
--    width = 400,
--    height = 400,
--    backgroundColor = { 0.7, 0.5, 0.2 }
--}
--
--button.widgets = { button2 }
--image.widgets = { button }
--image2.widgets = { image }
--
--local imageX = image.x
--local imageY = image.y
--local xRandom = 0
--local yRandom = 0
--
--function image:update()
--    xRandom = 5 - math.random() * 10
--    yRandom = 5 - math.random() * 10
--
--    if self:justDraggedBy(GUI.mouse.buttons.right) then
--        imageX = imageX + GUI.mouse.xChange
--        imageY = imageY + GUI.mouse.yChange
--    end
--    self.x = image2.x + imageX + xRandom
--    self.y = image2.y + imageY + yRandom
--end
--function image2:update()
--    if self:justDraggedBy(GUI.mouse.buttons.middle) then
--        self.x = self.x + GUI.mouse.xChange
--        self.y = self.y + GUI.mouse.yChange
--    end
--end
--
--local boxSelect = BoxSelect.new()

--local line = PolyLine.new{
--    x = 0,
--    y = 0,
--    width = 200,
--    height = 100,
--}
--local x = 0
--for i = 1, 1000 do
--    PolyLine.insertPoint(line, {
--        x = x,
--        y = 200 * math.random()
--    })
--    x = x + 1
--end

--GUI.window.widgets = { image2, boxSelect }
--
--GUI.run()