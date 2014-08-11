if not Entity then require("entity") end

-- TODO convert these to unique constants
-- rather than strings
local PRESSED      = "pressed"
local RELEASED     = "released"
local HOLDING      = "holding"

return function (x, y, controls, name)
    local controls = require('controls')[controls]
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)
    local facing, facing_wall

    local image = love.graphics.newImage('assets/spritesheets/' .. name .. '.png')

    -- TODO should this live in armor?
    local bump_damage = 4

    -- TODO should this live in armor?
    local damaged_speed           = 1
    local dx, dy

    local entity = Entity(x, y, 12, 29)
    local width  = entity.getWidth()
    local height = entity.getHeight()

    local senses_width    = (5/2)*width
    local senses_height   = height
    local senses_offset_x = senses_width/2 - width/2
    local senses_offset_y = height - senses_height

    local entity         = Entity(x, y, width, height, global.z_orders.sprites)
    local senses         = Entity(x - senses_offset_x, y + senses_offset_y, senses_width, senses_height, global.z_orders.sprites)

    local obstacleFilter = entity.getFilterFor('isObstacle')

    local sprite_box_offset_x = 20
    local sprite_box_offset_y = 9

    local movement, armor, x_buster, animation
    local FALLING, CAN_DASH, WALL_JUMP, AIR_DASH, SHOCKED, DASH_JUMP, MEGA_BLAST

    entity.set("name", name)

    entity.adjustX = function (dx)
        entity.setX(entity.getX() + dx)
        senses.setX(senses.getX() + dx)
    end

    entity.adjustY = function (dy)
        entity.setY(entity.getY() + dy)
        senses.setY(senses.getY() + dy)
    end

    -- ensures that the player's senses get added to the world
    entity.onRegister = function (world)
        world.bump:add(entity, entity.getBoundingBox())
        world.bump:add(senses, senses.getBoundingBox())
        entity.set("death_line", world.death_line)
    end

    -- registers another entity in the world on behalf of the player
    -- things like smoke and sparks... TODO and bullets?
    entity.register = function (other)
        world:register(other)
    end

    entity.setFacing = function (new_facing)
        -- we have to flip his collision box
        if new_facing == LEFT and entity.getFacing() ~= new_facing then
            sprite_box_offset_x = 17
        end

        if new_facing == RIGHT and entity.getFacing() ~= new_facing then
            sprite_box_offset_x = 22
        end

        facing = new_facing
    end

    entity.getFacing = function ()
        return facing
    end

    entity.getFacingWall = function ()
        return facing_wall
    end

    entity.setFacingWall = function (facing)
        facing_wall = facing
    end

    entity.setDeltaY = function (delta)
        dy = delta
    end

    entity.getDeltaY = function ()
        return dy
    end

    entity.init = function (Movement, Armor, XBuster, Animation)

        movement = Movement(entity, controls)
        armor    = Armor(entity, controls)
        x_buster = XBuster(entity, controls, world)

        animation = AnimationModule(entity, image, movement, armor, x_buster, controls)

        entity.incrementAmmo = x_buster.incrementAmmo

        -- TODO would be better if we could declare these as the only available
        -- boolean registers. Like, entity's get/set method only responds to these
        -- keys
        FALLING, CAN_DASH, WALL_JUMP, AIR_DASH, SHOCKED, DASH_JUMP = unpack(movement.register_keys)
        MEGA_BLAST, SHOCKED = unpack(x_buster.register_keys)

        entity.setFacing(RIGHT)
        entity.setDeltaY(0)
        entity.set("hp", 16)

        entity.set("isBullet", true)
        entity.set("damage", bump_damage)
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
                    entity.setDeltaY(0)
                    entity.set(FALLING, false)
                elseif(ny == 1) then
                    -- we bonked out head
                    entity.setDeltaY(0)
                    entity.set(FALLING, true)
                end

                -- megaman hits a wall
                if (nx == 1 or nx == -1) then
                    if movement.is("falling") or movement.is("climbing") then
                        movement.set("climbing")
                        entity.setDeltaY(0)
                        sy = sy + 1
                    end
                end

                entity.adjustX(tx - entity.getX())
                entity.adjustY(ty - entity.getY())
                world.bump:move(entity, entity.getX(), entity.getY())
                world.bump:move(senses, senses.getX(), senses.getY())

                cols, len = world.bump:check(entity, sx, sy, obstacleFilter)
                if len == 0 then
                    entity.adjustX(sx - entity.getX())
                    entity.adjustY(sy - entity.getY())
                    world.bump:move(entity, entity.getX(), entity.getY())
                    world.bump:move(senses, senses.getX(), senses.getY())
                end
            end
        end
    end

    entity.bump_check = function (entity, x, y, filter)
        return world.bump:check(entity, x, y, filter)
    end

    entity.resolveWallProximity = function()
        local cols, len = entity.bump_check(senses, new_x, new_y, obstacleFilter)

        if len == 0 then
            -- any time megaman can't find a wall or floor or ceiling
            entity.setFacingWall(nil)
        else
            local col, tx, ty, sx, sy

            for i, col in ipairs(cols) do
                local tx, ty, nx, ny, sx, sy = col:getSlide()

                -- megaman is near a wall he picks up a "near a wall"
                -- which he can use to kick off a wall from falling
                if movement.is("climbing") or movement.is("wall_jump") or movement.is("jumping") or movement.is("falling") then
                    if (nx == 1) then
                        entity.setFacingWall(LEFT)
                    elseif (nx == -1) then
                        entity.setFacingWall(RIGHT)
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

        if armor.is("destroyed") then
        end
    end

    entity.remove = function ()
        if world.bump:hasItem(entity) then
            world.bump:remove(entity)
            world.bump:remove(senses)
        end
    end

    entity.update = function (dt, world)
        local old_x, old_y = entity.getX(), entity.getY()

        for i, key in pairs(controls) do
            if entity.pressed(key) then
                entity.set(key, HOLDING)

            elseif entity.released(key) then
                entity.set(key, false)
            end
        end

        movement.update(dt)
        armor.update(dt)
        x_buster.update(dt)
        animation.update(dt)

        -- TODO this return is a temporary fix
        -- the module updates are happening in the middle
        -- of this update function, but they shouldn't be
        -- basically all the code to come should move into the
        -- modules and shouldn't depend on armor not being
        -- destroyed
        if armor.is("destroyed") then return end

        -- TODO this code calls resolve fall and should probably
        -- live in movement, but it relies on WORLD

        -- after we resolve falling we need to reset
        -- if megaman was dashing, but track that a
        -- change occurred
        if not movement.is("dashing") then
            movement.resolveFall(dt)
            -- face forward but slide back
            if armor.is('damaged') then
                movement.move(entity.getFacing(), -damaged_speed)
            end
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
        entity.resolveWallProximity()

        -- if after all this, megaman's position had not changed, then set
        -- a flag to animate him as standing
        -- TODO we should store megaman's velocity as a vector, even though we aren't
        -- doing physics that way, so that we can check facing and did move in a consistent
        -- manner
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

        -- this should buffer the shot, but the transition
        -- should happen in the update function
        if key == SHOOT then
            x_buster.keyreleased(key)
        end

        animation.update(0)

        entity.set(key, false)
    end

    entity.draw       = function ()
        local draw_x = entity.getX()
        local draw_y = entity.getY()

        if entity.getFacing() == LEFT then
            -- love.graphics.line(draw_x, draw_y, draw_x, draw_y + height)
        else
            -- love.graphics.line(draw_x + width, draw_y, draw_x + width, draw_y + height)
        end

        local flicker = 0
        if x_buster.is("charging") then

            love.graphics.setColor(COLOR.CYAN)

            if entity.get(MEGA_BLAST) then
                love.graphics.setColor(COLOR.YELLOW)
            end

            flicker = rng:random(0, 1)
            if flicker == 1 then
                love.graphics.setColor(COLOR.BLACK)
            end
        end

        if armor.is("damaged") then
            local r, g, b = love.graphics.getColor()
          --love.graphics.setColor(COLOR.YELLOW)
          --love.graphics.rectangle("fill", draw_x - 5, draw_y - 5, width + 10, height + 10)
          --love.graphics.setColor({ r, g, b })
        end

        if armor.is("destroyed") then
            love.graphics.setColor(COLOR.BLACK)
        end

        -- TODO ha ha ha
        local flicker = 0
        if entity.get("invulnerable") then
            flicker = rng:random(0, 1)
        end

        if flicker == 0 then
            if armor.is("destroyed") then
                armor.draw()
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

    entity.isDashing = function ()
        return movement.is("dashing")
    end

    return entity
end
