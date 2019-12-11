local ECS = require("ECS")

ECS.addSystem(require("RectangleMouseBehavior"))
ECS.addSystem(require("BoxSelectMouseBehavior"))
ECS.addSystem(require("ButtonMouseBehavior"))
ECS.addSystem(require("PolyLineState"))
ECS.addSystem(require("ButtonDraw"))
ECS.addSystem(require("PolyLineDraw"))
ECS.addSystem(require("BoxSelectDraw"))

return ECS