local type = type

local ECS = {}

local systems = {}

local function initializeEntityBasedOnSystem(system, entity)
    for k, v in pairs(system.getDefaults()) do if entity[k] == nil then entity[k] = v end end
end
local function addEntityToSystem(system, entity)
    initializeEntityBasedOnSystem(system, entity)
    system.entities[#system.entities + 1] = entity
end

function ECS.addSystem(system)
    if type(system.entities) ~= "table" then
        system.entities = {}
    end
    systems[#systems + 1] = system
end
function ECS.addEntity(entity)
    for i = 1, #systems do
        local system = systems[i]
        if system.requires(entity) then
            addEntityToSystem(system, entity)
        end
    end
end
function ECS.update(dt)
    for i = 1, #systems do
        local system = systems[i]
        local systemEntities = system.entities
        for j = 1, #systemEntities do
            system.update(systemEntities[j], dt)
        end
    end
end

return ECS