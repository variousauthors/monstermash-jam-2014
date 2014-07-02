if not Entity then require("entity") end

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

Bullet = function (x, y, owner)
    local entity = Entity(x, y)

    if owner.get("bullet_count") then
        local count = owner.get("bullet_count")
        owner.set("bullet_count", count + 1)
    else
        owner.set("bullet_count", 1)
    end

    entity.draw = function ()
        love.graphics.setColor(COLOR.YELLOW)
        love.graphics.rectangle("fill", entity.getX(), entity.getY(), 4, 2)
        love.graphics.setColor(COLOR.WHITE)
    end

    entity.update = function (dt)
        entity.setX(entity.getX() + 2)
    end

    entity.set("owner_id", owner.get("id"))

    entity.cleanup = function ()
        local count = owner.get("bullet_count")
        owner.set("bullet_count", count - 1)
        entity.set("owner_id", nil)
    end

    return entity
end

return function (x, y)
    local entity    = Entity(x, y)
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
    local initial_vertical_speed  = 5
    local terminal_vertical_speed = 5.75
    local vertical_speed          = 0
    local gravity                 = 0.25

    entity.set("facing", RIGHT)

    entity.setJumpOrigin = function ()
        jump_origin = Point(entity.getX(), entity.getY())
    end

    entity.startJump = function ()
        vertical_speed = initial_vertical_speed
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
    controls[LEFT] = function ()
        if movement.is("dashing") then return end

        local speed = horizontal_speed

        if entity.get("dash_jump") then
            speed = horizontal_speed*2
        end

        entity.set(DASH, false)

        entity.setX(entity.getX() - speed)
        entity.set("facing", LEFT)
    end

    controls[RIGHT] = function ()
        if movement.is("dashing") then return end

        local speed = horizontal_speed

        if entity.get("dash_jump") then
            speed = horizontal_speed*2
        end

        entity.set(DASH, false)

        entity.setX(entity.getX() + speed)
        entity.set("facing", RIGHT)
    end

    controls[JUMP] = function (dt)
        -- even if the jump button is down, we don't
        -- want to run this function unless the player is jumping
        if not movement.is("jumping") and not movement.is("dash_jump") then return end

        vertical_speed = math.max(vertical_speed - gravity, 0)

        entity.setY(entity.getY() - vertical_speed)

        if vertical_speed == 0 then
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
    end

    local falling = function (dt)
        vertical_speed = math.min(vertical_speed + gravity, terminal_vertical_speed)

        entity.setY(entity.getY() + vertical_speed)

        if entity.getY() > FLOOR_HEIGHT then
            entity.set(FALLING, false)
            entity.setY(FLOOR_HEIGHT)
        end
    end

    local willMove = function ()
        return will_move ~= nil
    end

    -- every tick, set the current maneuver
    entity.tic = function ()
        if willMove() then
            will_move = nil
        end
    end

    entity.update = function (dt)
        movement.update()
        x_buster.update()

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
            shoot(dt)
        end

        if entity.get(FALLING) then
            falling(dt)
        end
    end

    entity.draw       = function ()
        local draw_x = entity.getX() + width
        local draw_y = entity.getY() - height

        love.graphics.setColor(COLOR.BLACK)
        if entity.get("facing") == LEFT then
            love.graphics.line(draw_x, draw_y, draw_x, draw_y + height)
        else
            love.graphics.line(draw_x + width, draw_y, draw_x + width, draw_y + height)
        end

        if movement.is("running") then
            love.graphics.setColor(COLOR.RED)
        elseif movement.is("jumping") or movement.is("falling") then
            love.graphics.setColor(COLOR.GREEN)
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

        love.graphics.rectangle("fill", draw_x, draw_y, width, height)
        love.graphics.setColor(COLOR.WHITE)
    end

    entity.keypressed = function (key)
        entity.set(key, "pressed")
    end

    entity.keyreleased = function (key)
        entity.set(key, false)
    end

    return entity
end
