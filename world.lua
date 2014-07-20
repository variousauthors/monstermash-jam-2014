if not Entity then require("entity") end

local bump = require('vendor/bump/bump')
json = json or require('vendor/dkjson')

local World = {}
World.__index = World

--Private Methods

local function addObstacle(self, x,y,w,h)
    local obstacle = Entity(x, y, w, h)
    obstacle.set('isObstacle', true)
    self.obstacles[#self.obstacles+1] = obstacle
    self.bump:add(obstacle, x, y, w, h)
end

local function drawBox(box, r,g,b)
    local _r, _g, _b, _a = love.graphics.getColor()
    local x, y, w, h = box.getBoundingBox()
    love.graphics.setColor(r,g,b,70)
    love.graphics.rectangle("fill", x, y, w, h)
    love.graphics.setColor(r,g,b)
    love.graphics.rectangle("line", x+0.5, y+0.5, w-1, h-1)
    love.graphics.setColor(_r,_g,_b,_a)
end

--Public Methods

function World.new()
    local self = {}
    setmetatable(self, World)

    local contents, size = love.filesystem.read("assets/arena_highway.json")
    self.data = json.decode(contents)

    self.background_image = love.graphics.newImage("assets/arena_highway_bg.png")
    self.foreground_image = love.graphics.newImage("assets/arena_highway_fg.png")

    self.timer = 0
    self.tic_duration = 1

    return self
end

-- broke init out of new so that we can pass references to world in lua.load
-- but initialize it when the game starts
function World:init()
    self.entities = {}

    self.obstacles = {}
    self.bump = bump.newWorld(32)

    for i, v in pairs(self.data["layers"][2]["objects"]) do
        addObstacle(self, v.x, v.y, v.width, v.height)
    end

    return self
end

function World:register(entity)
    self.entities[entity.get("id")] = entity

    if entity.register then
        entity.register(self)
    else
        self.bump:add(entity, entity.getBoundingBox())
    end

    entity._unregister = function ()
        world:unregister(entity)
    end
end

function World:unregister(entity)
    self.entities[entity.get("id")] = nil
    entity.cleanup()

    if world.bump:hasItem(entity) then
        self.bump:remove(entity)
    end
end

function World:tic(dt)
    self.timer = self.timer + dt

    if self.timer > self.tic_duration then
        for i, entity in pairs(self.entities) do
            entity.tic()
        end

        self.timer = 0
    end
end

function World:keypressed(key)
    for i, entity in pairs(self.entities) do
        if entity.keypressed then entity.keypressed(key) end
    end
end

function World:keyreleased(key)
    for i, entity in pairs(self.entities) do
        if entity.keyreleased then entity.keyreleased(key) end
    end
end

function World:update(dt)
    self:tic(dt)
    inspect(self.entities)
    -- iterate over the entities
    -- each of them that has queued a movement for this dt
    -- should try to move
    -- then resolve any collisions

    for i, entity in pairs(self.entities) do
        entity.update(dt, self)
    end
end

function World:draw(dt)
    love.graphics.draw(self.background_image)

    for i, entity in pairs(self.entities) do
        entity.draw(dt)
    end

    love.graphics.draw(self.foreground_image)
end

function World:serialize()
    local data = {}

    for i, entity in pairs(self.entities) do
        table.insert(data, { entity.get("id"), entity.getX(), entity.getY() })
    end

    return data
end

return World
