local Button = require("Button")
local Drawable = require("Drawable")
local DrawableButton = require("DrawableButton")

return function(self, buttonState, drawableState, drawableButtonState)
    local self = self or {}

    local buttonState = buttonState or {}
    local drawableState = drawableState or {}
    local drawableButtonState = drawableButtonState or {}

    buttonState.isPressed = buttonState.isPressed or false

    drawableState.alpha = drawableState.alpha or 1
    drawableState.blendMode = drawableState.blendMode or 0

    drawableButtonState.width = drawableButtonState.width or 100
    drawableButtonState.height = drawableButtonState.height or 40
    drawableButtonState.bodyColor = drawableButtonState.bodyColor or { 0.4, 0.4, 0.4, 1, 0 }
    drawableButtonState.outlineColor = drawableButtonState.outlineColor or { 0.15, 0.15, 0.15, 1, 0 }
    drawableButtonState.highlightColor = drawableButtonState.highlightColor or { 1, 1, 1, 0.15, 1 }
    drawableButtonState.pressedColor = drawableButtonState.pressedColor or { 1, 1, 1, -0.15, 1 }

    Button(self, buttonState)
    Drawable(self, drawableState)
    DrawableButton(self, drawableButtonState)

    return self
end