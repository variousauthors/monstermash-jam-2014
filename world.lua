if not Entity then require("entity") end

local class = require('vendor/middleclass/middleclass')
local bump = require('vendor/bump/bump')

local World = class('World')

--Private Methods

local function addObstacle(self, x,y,w,h)
    local obstacle = Entity(x, y, w, h)
    obstacle.set('isObstacle', true)
    self.obstacles[#self.obstacles+1] = obstacle
    self.bump:add(obstacle, x,y,w,h)
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

function World:initialize()
    self.entities = {}

    self.obstacles = {}
    self.bump = bump.newWorld(64)
    addObstacle(self, 0,   0,   256, 15)
    addObstacle(self, 0,   15,  16,  176)
    addObstacle(self, 240, 15,  16,  176)
    addObstacle(self, 0,   191, 256, 32)
    addObstacle(self, 80, 135, 32, 8)
    addObstacle(self, 160, 145, 32, 8)

    self.background_image = love.graphics.newImage("assets/chillpenguinstage.png")

    self.timer = 0
    self.tic_duration = 5
end

function World:register(entity)
    self.entities[entity.get("id")] = entity
    self.bump:add(entity, entity.getBoundingBox())
end

function World:unregister(entity)
    self.entities[entity.get("id")] = nil
    entity.cleanup()
end

function World:tic(dt)
    self.timer = self.timer + dt

    if self.timer > self.tic_duration then
        for i, entity in ipairs(self.entities) do
            entity.tic()
        end

        self.timer = 0
    end
end

function World:update(dt)
    self:tic(dt)
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

    for i, obstacle in pairs(self.obstacles) do
        drawBox(obstacle, 255,0,0)
    end
end

return World
