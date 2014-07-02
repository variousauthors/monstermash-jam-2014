if not Entity then require("entity") end
if not BulletFactory then require("bullet_factory") end

-- TODO convert these to unique constants
-- rather than strings
PRESSED = "pressed"
HOLDING = "holding"

LEFT         = "left"
RIGHT        = "right"
JUMP         = "z"
SHOOT        = "x"
DASH         = "lshift"
FALLING      = "falling"
FLOOR_HEIGHT = 170

MovementModule = require("player_movement")
XBuster        = require("arm_cannon")

Pellet    = BulletFactory(3, 4, 4, 1, COLOR.YELLOW, "pellet")
Blast     = BulletFactory(4, 20, 5, 2, COLOR.GREEN, "blast")
MegaBlast = BulletFactory(3, 15, 20, 3, COLOR.RED, "mega_blast")

Bullets = {
    pellet     = Pellet,
    blast      = Blast,
    mega_blast = MegaBlast
}

return function (x, y)
    local will_move = nil
    local maneuver  = nil
    local shooting  = false

    -- back of glove to beginning of red thing
    -- red thing is top
    local height      = 30
    local width       = 15
    local max_bullets = 3

    local jump_origin
    local fat_gun_dim             = 3
    local horizontal_speed        = 1.5
    local damaged_speed           = 1
    local initial_vs  = 5
    local terminal_vs = 5.75
    local gravity                 = 0.25

    local entity         = Entity(x, y, width, height)
    local obstacleFilter = entity.getFilterFor('isObstacle')
    local bulletFilter = function (other)
        return other.get and other.get("isBullet") == true and other.get("owner_id") ~= entity.get("id")
    end


    entity.set("facing", RIGHT)
    entity.set("vs", 0)
    entity.set("hp", 10)

    -- TODO player's collide with enemies causing damage
    -- this is just to test
    entity.set("isBullet", true)
    entity.set("damage", 1)

    entity.setJumpOrigin = function ()
        jump_origin = Point(entity.getX(), entity.getY())
    end

    entity.startJump = function ()
        entity.set("vs", initial_vs)
    end

    entity.pressed = function (key)
        return entity.get(key) == PRESSED
    end

    entity.holding = function (key)
        return entity.get(key) == HOLDING
    end

    local movement = MovementModule(entity)
    local x_buster = XBuster(entity)

    local controls = {}

    local move = function (direction, speed)
        if movement.is("dashing") then return end

        local sign = (direction == LEFT) and -1 or 1

        if entity.get("dash_jump") then
            speed = horizontal_speed*2
        end

        entity.set(DASH, false)

        entity.setX(entity.getX() + sign*speed)
        entity.set("facing", direction)
    end

    controls[LEFT] = function ()
        move(LEFT, horizontal_speed)
    end

    controls[RIGHT] = function ()
        move(RIGHT, horizontal_speed)
    end

    controls[JUMP] = function (dt)
        -- even if the jump button is down, we don't
        -- want to run this function unless the player is jumping
        if not movement.is("jumping") and not movement.is("dash_jump") then return end

        entity.set("vs", math.max(entity.get("vs") - gravity, 0))

        entity.setY(entity.getY() - entity.get("vs"))

        if entity.get("vs") == 0 then
            entity.set(FALLING, true)
        end
    end

    controls[DASH] = function (dt)
        if not movement.is("dashing") then return end

        local speed = horizontal_speed*2
        local sign = 1

        if entity.get("facing") == LEFT then sign = -1 end

        entity.setX(entity.getX() + sign*speed)
    end

    controls[SHOOT] = function (dt)
    end

    local shoot = function (dt)
        local offset       = width
        local bullet_type  = x_buster.getState()
        local bullet_count = entity.get(bullet_type)
        local bullet

        if entity.get("facing") == LEFT then
            offset = 0 - fat_gun_dim*2
        end

        if not bullet_count or bullet_count < max_bullets then
            bullet = Bullets[x_buster.getState()](entity.getX() + offset, entity.getY() + 1*height/3 + fat_gun_dim/2, entity)
        end

        return bullet
    end

    local falling = function (dt)
        if movement.is('jumping') then return end

        -- face forward but slide back
        if movement.is('damaged') then
            move(entity.get("facing"), -damaged_speed)
        end

        entity.set("vs", math.min(entity.get("vs") + gravity, terminal_vs))

        entity.setY(entity.getY() + entity.get("vs"))
    end

    local willMove = function ()
        return will_move ~= nil
    end

    entity.resolveObstacleCollide = function(world)
        local new_x, new_y = entity.getX(), entity.getY()
        local cols, len = world.bump:check(entity, new_x, new_y, obstacleFilter)
        if len == 0 then
            world.bump:move(entity, new_x, new_y)
        else
            local col, tx, ty, sx, sy
            while len > 0 do
                local col = cols[1]
                local tx, ty, nx, ny, sx, sy = col:getSlide()
                if(ny == -1) then
                    entity.set("vs", 0)
                    entity.set(FALLING, false)
                elseif(ny == 1) then
                    entity.set("vs", 0)
                    entity.set(FALLING, true)
                end
                entity.setX(tx)
                entity.setY(ty)
                world.bump:move(entity, tx, ty)
                cols, len = world.bump:check(entity, sx, sy, obstacleFilter)
                if len == 0 then
                    entity.setX(sx)
                    entity.setY(sy)
                    world.bump:move(entity, sx, sy)
                end
            end
        end
    end

    entity.resolveBulletCollide = function(world)
        local x, y = entity.getX(), entity.getY()
        local cols, len = world.bump:check(entity, x, y, bulletFilter)

        while len > 0 and not entity.get("invulnerable") do
            local col            = cols[1]
            local bullet         = col.other
            local tx, ty, nx, ny = col:getTouch()

            local entity_center = entity.getX() + col.itemRect.w/2
            local bullet_center = bullet.getX() + col.otherRect.w/2
            local facing        = (entity_center > bullet_center) and LEFT or RIGHT

            entity.set("damage_queue", bullet.get("damage"))
            entity.set("facing", facing) -- megaman always turns to face the damage source
            movement.update()
            x_buster.start("inactive")

            -- if there is something the bullet needs to do
            if bullet.resolveCollide then
                bullet.resolveCollide()
            end

            cols, len = world.bump:check(entity, x, y, bulletFilter)
        end
    end

    -- every tick, set the current maneuver
    entity.tic = function (dt)
        if entity.get("invulnerable") and entity.get("invulnerable") > 0 then
            entity.set("invulnerable", math.max(entity.get("invulnerable") - 1, 0))

            if entity.get("invulnerable") == 0 then entity.set("invulnerable", nil) end
        end
    end

    entity.update = function (dt, world)
        for k, v in pairs(controls) do
            -- the player is holding a key as long as it is down, and we
            -- received input in this or some previous update
            if (entity.pressed(k) or entity.holding(k)) and love.keyboard.isDown(k) then
                entity.set(k, HOLDING)

                v(dt)
            else
                entity.set(k, false)
            end
        end

        if x_buster.isSet("shoot") then
            local bullet = shoot(dt)

            if bullet then world:register(bullet) end
        end

        falling(dt)

        -- Resolve collision
        entity.resolveObstacleCollide(world)
        entity.resolveBulletCollide(world)

        movement.update()
        x_buster.update()
    end

    entity.draw       = function ()
        local draw_x = entity.getX()
        local draw_y = entity.getY()

        love.graphics.setColor(COLOR.BLACK)
        if entity.get("facing") == LEFT then
            love.graphics.line(draw_x, draw_y, draw_x, draw_y + height)
        else
            love.graphics.line(draw_x + width, draw_y, draw_x + width, draw_y + height)
        end

        if movement.is("running") then
            love.graphics.setColor(COLOR.RED)
        elseif movement.is("jumping") then
            love.graphics.setColor(COLOR.GREEN)
        elseif movement.is("falling") then
            love.graphics.setColor(COLOR.PURPLE)
        else
            love.graphics.setColor(COLOR.BLUE)
        end

        if x_buster.is("charging") then
            love.graphics.setColor(COLOR.CYAN)

            if x_buster.isSet("mega_blast") then
                love.graphics.setColor(COLOR.YELLOW)
            end
        end

        if x_buster.is("pellet") or x_buster.is("cool_down") or x_buster.is("charging") then
            local offset = width

            if entity.get("facing") == LEFT then
                offset = 0 - fat_gun_dim*2
            end

            love.graphics.rectangle("fill", draw_x + offset, draw_y + 1*height/3, fat_gun_dim * 2, fat_gun_dim)
        end

        if movement.is("damaged") then
            local r, g, b = love.graphics.getColor()
            love.graphics.setColor(COLOR.YELLOW)
            love.graphics.rectangle("fill", draw_x - 5, draw_y - 5, width + 10, height + 10)
            love.graphics.setColor({ r, g, b })
        end

        -- TODO ha ha ha
        local flicker = 0
        if entity.get("invulnerable") then
            flicker = rng:random(0, 1)
        end

        if flicker == 0 then
            if movement.is("dashing") then
                local verts
                local lean = 5

                if entity.get("facing") == LEFT then
                    verts = { draw_x - lean, draw_y, draw_x + width - lean, draw_y, draw_x + width, draw_y + height, draw_x, draw_y + height }
                else
                    verts = { draw_x + lean, draw_y, draw_x + width + lean, draw_y, draw_x + width, draw_y + height, draw_x, draw_y + height }
                end

                love.graphics.polygon("fill", verts)
            else
                love.graphics.rectangle("fill", draw_x, draw_y, width, height)
            end
        end

        love.graphics.setColor(COLOR.WHITE)
    end

    entity.keypressed = function (key)
        entity.set(key, PRESSED)

        movement.update()
        x_buster.update()
    end

    entity.keyreleased = function (key)
        entity.set(key, false)
    end

    return entity
end
