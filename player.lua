if not Entity then require("entity") end
if not BulletFactory then require("bullet_factory") end

-- TODO convert these to unique constants
-- rather than strings
PRESSED      = "pressed"
RELEASED     = "released"
HOLDING      = "holding"
FALLING      = "falling"

MovementModule  = require("player_movement")
AnimationModule = require("player_animation")
XBuster         = require("arm_cannon")

Pellet    = BulletFactory(5, 4, 4, 1, COLOR.YELLOW, "pellet")
Blast     = BulletFactory(6, 20, 5, 2, COLOR.GREEN, "blast")
MegaBlast = BulletFactory(5, 15, 20, 3, COLOR.RED, "mega_blast")

Bullets = {
    pellet     = Pellet,
    blast      = Blast,
    mega_blast = MegaBlast
}

return function (x, y, controls, name)
    local controls = require('controls')[controls]
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)

    local ring_timer       = 0
    local ring_timer_limit = 100
    local ring_count       = 1
    local ring_speed       = 40
    local ring_limit       = 2

    -- back of glove to beginning of red thing
    -- red thing is top
    local height      = 29
    local width       = 12
    local max_bullets = 3

    local fat_gun_dim             = 3
    local horizontal_speed        = 1.5
    local dash_speed              = 3.5
    local damaged_speed           = 1
    local initial_vs  = 5
    local terminal_vs = 5.75
    local gravity                 = 0.25

    local senses_width    = (5/2)*width
    local senses_height   = height
    local senses_offset_x = senses_width/2 - width/2
    local senses_offset_y = height - senses_height

    local entity         = Entity(x, y, width, height)
    local senses         = Entity(x - senses_offset_x, y + senses_offset_y, senses_width, senses_height)

    local obstacleFilter = entity.getFilterFor('isObstacle')
    local bulletFilter = function (other)
        return other.get and other.get("isBullet") == true and other.get("owner_id") ~= entity.get("id")
    end

    entity.register = function (world)
        world.bump:add(entity, entity.getBoundingBox())
        world.bump:add(senses, senses.getBoundingBox())
    end

    local sprite_box_offset_x = 20
    local sprite_box_offset_y = 9

    entity.setFacing = function (facing)
        -- we have to flip his collision box
        if facing == LEFT and entity.get("facing") ~= facing then
            sprite_box_offset_x = 17
        end

        if facing == RIGHT and entity.get("facing") ~= facing then
            sprite_box_offset_x = 22
        end

        entity.set("facing", facing)
    end

    entity.setFacing(RIGHT)
    entity.set("vs", 0)
    entity.set("initial_vs", initial_vs)
    entity.set("hp", 16)

    -- TODO player's collide with enemies causing damage
    -- this is just to test
    entity.set("isBullet", true)
    entity.set("damage", 4)

    entity.startJump = function ()
        entity.set("vs", initial_vs)
    end

    entity.pressed = function (key)
        return entity.get(key) == PRESSED
    end

    entity.released = function (key)
        return entity.get(key) == RELEASED
    end

    entity.holding = function (key)
        return entity.get(key) == HOLDING
    end

    local image     = love.graphics.newImage('assets/spritesheets/' .. name .. '.png')
    entity.set("name", name)

    local movement  = MovementModule(entity, world, controls)
    local x_buster  = XBuster(entity, controls)
    local animation = AnimationModule(entity, image, movement, x_buster, controls)

    local move = function (direction, speed)
        local sign = (direction == LEFT) and -1 or 1

        if entity.get("dash_jump") then
            speed = dash_speed
        end

        entity.set(DASH, false)

        entity.setX(entity.getX() + sign*speed)
        senses.setX(senses.getX() + sign*speed)
    end

    entity.resolveLeft = function ()
        move(LEFT, horizontal_speed)
        entity.setFacing(LEFT)
    end

    entity.resolveRight = function ()
        move(RIGHT, horizontal_speed)
        entity.setFacing(RIGHT)
    end

    entity.resolveJump = function (dt)
        if entity.get("wall_jump") then
            local away = entity.get("near_a_wall") == LEFT and RIGHT or LEFT

            move(away, 1)
            entity.setFacing(entity.get("near_a_wall"))

            -- removed this while fixing wall jump: we'll set near a wall to nil when the
            -- player's senses are not colliding with a wall
            -- entity.set("near_a_wall", nil)
        end

        entity.setY(entity.getY() - entity.get("vs"))
        senses.setY(senses.getY() - entity.get("vs"))
        entity.set("vs", math.max(entity.get("vs") - gravity, 0))
    end

    entity.resolveDash = function (dt)
        local speed = horizontal_speed*2
        local sign = 1

        if entity.get("facing") == LEFT then sign = -1 end

        entity.setX(entity.getX() + sign*speed)
        senses.setX(senses.getX() + sign*speed)
    end

    entity.resolveShoot = function (dt)
        local offset       = width
        local bullet_type  = x_buster.getState()
        local bullet_count = entity.get(bullet_type)
        local bullet
        local direction = (entity.get("facing") == LEFT and -1 or 1)

        if entity.get("facing") == LEFT then
            offset = 0 - fat_gun_dim*2
        end

        if not bullet_count or bullet_count < max_bullets then
            bullet = Bullets[x_buster.getState()](entity.getX() + offset, entity.getY() + 1*height/3 + fat_gun_dim/2, entity, direction)
        end

        return bullet
    end

    entity.resolveFall = function (dt)
        if movement.is("wall_jump") or movement.is('jumping') then return end

        -- face forward but slide back
        if movement.is('damaged') then
            move(entity.get("facing"), -damaged_speed)
        end

        entity.set("vs", math.min(entity.get("vs") + gravity, terminal_vs))

        entity.setY(entity.getY() + entity.get("vs"))
        senses.setY(senses.getY() + entity.get("vs"))
    end

    entity.resolveObstacleCollide = function(world)
        local new_x, new_y = entity.getX(), entity.getY()
        local cols, len = world.bump:check(entity, new_x, new_y, obstacleFilter)

        if len == 0 then
            world.bump:move(entity, new_x, new_y)
            world.bump:move(senses, new_x - senses_offset_x, new_y + senses_offset_y)
        else
            local col, tx, ty, sx, sy
            while len > 0 do
                local col = cols[1]
                local tx, ty, nx, ny, sx, sy = col:getSlide()

                if(ny == -1) then
                    -- we've landed on something
                    entity.set("vs", 0)
                    entity.set(FALLING, false)
                elseif(ny == 1) then
                    -- we bonked out head
                    entity.set("vs", 0)
                    entity.set(FALLING, true)
                end

                -- megaman hits a wall
                if (nx == 1 or nx == -1) then
                    if movement.is("falling") or movement.is("climbing") then
                        movement.set("climbing")
                        entity.set("vs", 0)
                        sy = sy + 1
                    end
                end

                entity.setX(tx)
                senses.setX(tx - senses_offset_x)
                entity.setY(ty)
                senses.setY(ty + senses_offset_y)
                world.bump:move(entity, entity.getX(), entity.getY())
                world.bump:move(senses, senses.getX(), senses.getY())

                cols, len = world.bump:check(entity, sx, sy, obstacleFilter)
                if len == 0 then
                    entity.setX(sx)
                    senses.setX(sx - senses_offset_x)
                    entity.setY(sy)
                    senses.setY(sy + senses_offset_y)
                    world.bump:move(entity, entity.getX(), entity.getY())
                    world.bump:move(senses, senses.getX(), senses.getY())
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
            entity.setFacing(facing)
            movement.update()
            x_buster.start("inactive")

            -- if there is something the bullet needs to do
            if bullet.resolveCollide then
                bullet.resolveCollide()
            end

            cols, len = world.bump:check(entity, x, y, bulletFilter)
        end
    end

    entity.resolveWallProximity = function(world)
        local cols, len = world.bump:check(senses, new_x, new_y, obstacleFilter)

        if len == 0 then
            -- any time megaman can't find a wall or floor or ceiling
            entity.set("near_a_wall", nil)
        else
            local col, tx, ty, sx, sy

            for i, col in ipairs(cols) do
                local tx, ty, nx, ny, sx, sy = col:getSlide()

                -- megaman is near a wall he picks up a "near a wall"
                -- which he can use to kick off a wall from falling
                if movement.is("climbing") or movement.is("wall_jump") or movement.is("jumping") or movement.is("falling") then
                    if (nx == 1) then
                        entity.set("near_a_wall", LEFT)
                    elseif (nx == -1) then
                        entity.set("near_a_wall", RIGHT)
                    end
                end
            end
        end

    end

    entity.tic = function (dt)

        if entity.get("invulnerable") and entity.get("invulnerable") > 0 then
            entity.set("invulnerable", math.max(entity.get("invulnerable") - 1, 0))

            if entity.get("invulnerable") == 0 then entity.set("invulnerable", nil) end
        end

        if movement.is("destroyed") then
            if ring_count < ring_limit then

                ring_count = ring_count + 1
            end
        end
    end

    entity.update = function (dt, world)
        local old_x, old_y = entity.getX(), entity.getY()

        if movement.is("destroyed") then
            if world.bump:hasItem(entity) then
                world.bump:remove(entity)
                world.bump:remove(senses)
            end

            ring_timer = ring_timer + ring_speed*dt
            if ring_timer > ring_timer_limit then
                entity._unregister()
            end

            return
        end

        for i, key in pairs(controls) do
            if entity.pressed(key) then
                entity.set(key, HOLDING)

            elseif entity.released(key) then
                entity.set(key, false)
            end
        end

        if x_buster.isSet("shoot") then
            local bullet = entity.resolveShoot()
            if bullet then world:register(bullet) end
        end

        movement.update(dt)
        x_buster.update(dt)
        animation.update(dt)

        local by = entity.getY()
        -- after we resolve falling we need to reset
        -- if megaman was dashing, but track that a
        -- change occurred
        if not movement.is("dashing") then
            entity.resolveFall(dt)
        else
            -- if megaman has nothing under him, then he would fall
            local cols, len = world.bump:check(entity, entity.getX(), entity.getY() + 1, obstacleFilter)

            if len == 0 then
                movement.set("would_fall")
            else
                movement.unset("would_fall")
            end
        end

        entity.resolveObstacleCollide(world)
        entity.resolveBulletCollide(world)
        entity.resolveWallProximity(world)

        -- if after all this, megaman's position had not changed, then set
        -- a flag to animate him as standing
        if entity.getX() == old_x and entity.getY() == old_y then
            entity.set("did_not_move", true)
        else
            entity.set("did_not_move", false)
        end
    end

    entity.keypressed = function (key)
        entity.set(key, PRESSED)

        movement.keypressed(key)
        x_buster.keypressed(key)
        animation.update(0)

        entity.set(key, HOLDING)
    end

    entity.keyreleased = function (key)
        entity.set(key, RELEASED)

        movement.keyreleased(key)

        if key == SHOOT then
            x_buster.keyreleased(key)
        end

        animation.update(0)

        entity.set(key, false)
    end

    entity.draw       = function ()
        local draw_x = entity.getX()
        local draw_y = entity.getY()

        if entity.get("facing") == LEFT then
            -- love.graphics.line(draw_x, draw_y, draw_x, draw_y + height)
        else
            -- love.graphics.line(draw_x + width, draw_y, draw_x + width, draw_y + height)
        end

      --if movement.is("running") then
      --    love.graphics.setColor(COLOR.RED)
      --elseif movement.is("jumping") then
      --    love.graphics.setColor(COLOR.GREEN)
      --elseif movement.is("falling") then
      --    love.graphics.setColor(COLOR.PURPLE)
      --elseif movement.is("climbing") then
      --    love.graphics.setColor(COLOR.GREY)
      --else
      --    love.graphics.setColor(COLOR.BLUE)
      --end

        local flicker = 0
        if x_buster.is("charging") then

            love.graphics.setColor(COLOR.CYAN)

            if x_buster.isSet("mega_blast") then
                love.graphics.setColor(COLOR.YELLOW)
            end

            flicker = rng:random(0, 1)
            if flicker == 1 then
                love.graphics.setColor(COLOR.BLACK)
            end
        end

        if x_buster.isSet("shoot") or x_buster.is("cool_down") then
            local offset = width

            if entity.get("facing") == LEFT then
                offset = 0 - fat_gun_dim*2
            end

            love.graphics.rectangle("fill", draw_x + offset, draw_y + 1*height/3, fat_gun_dim * 2, fat_gun_dim)
        end

        if movement.is("damaged") then
            local r, g, b = love.graphics.getColor()
          --love.graphics.setColor(COLOR.YELLOW)
          --love.graphics.rectangle("fill", draw_x - 5, draw_y - 5, width + 10, height + 10)
          --love.graphics.setColor({ r, g, b })
        end

        if movement.is("destroyed") then
            love.graphics.setColor(COLOR.BLACK)
        end

        -- TODO ha ha ha
        local flicker = 0
        if entity.get("invulnerable") then
            flicker = rng:random(0, 1)
        end

        if flicker == 0 then
            if movement.is("destroyed") then

                love.graphics.setColor(COLOR.CYAN)
                for j = 1, ring_count do
                    local r = ring_timer/j

                    for i = 1, 8 do
                        local rad = i*math.pi/4 + ring_timer
                        local x = r*4*math.cos(rad)
                        local y = r*4*math.sin(rad)

                        local rad2 = i*math.pi/4 + ring_timer + math.pi/3
                        local x2 = r*4.2*math.cos(rad2)
                        local y2 = r*4.2*math.sin(rad2)

                        love.graphics.rectangle("fill", draw_x + x, draw_y + y, 5, 5)
                        love.graphics.rectangle("fill", draw_x + x2, draw_y + y2, 5, 5)
                    end
                end
            else
                animation.draw(draw_x - sprite_box_offset_x, draw_y - sprite_box_offset_y)
            end
        end


--    love.graphics.rectangle("line", draw_x, draw_y, width, height)
--    love.graphics.rectangle("line", senses.getX(), senses.getY(), senses_width, senses_height)
      --love.graphics.rectangle("line", draw_x - sprite_box_offset_x, draw_y - sprite_box_offset_y, 51, 51)
      --love.graphics.line(draw_x - sprite_box_offset_x + sprite_width/2, draw_y - sprite_diff, draw_x - sprite_box_offset_x + sprite_width/2, draw_y + sprite_box_offset_y + sprite_diff)
        love.graphics.setColor(COLOR.WHITE)
    end

    return entity
end
