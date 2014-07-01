if not Entity then require("entity") end

-- TODO convert these to unique constants
-- rather than strings
PRESSED = "pressed"
HOLDING = "holding"

LEFT         = "left"
RIGHT        = "right"
JUMP         = "z"
SHOOT        = "x"
DASH         = "shift"
FALLING      = "falling"
FLOOR_HEIGHT = 170

MovementModule = require("player_movement")
XBuster        = require("arm_cannon")

return function (x, y)
    local entity    = Entity()
    local p         = Point(x, y)
    local will_move = nil
    local maneuver  = nil
    local facing    = RIGHT
    local shooting  = false

    -- back of glove to beginning of red thing
    -- red thing is top
    local height = 30
    local width  = 15

    local fat_gun_dim             = 3
    local jump_origin
    local horizontal_speed        = 1.5
    local initial_vertical_speed  = 5
    local terminal_vertical_speed = 5.75
    local vertical_speed          = 0
    local gravity                 = 0.25

    entity.setJumpOrigin = function ()
        jump_origin = p.copy()
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
        p.setX(p.getX() - horizontal_speed)
        facing = LEFT
    end

    controls[RIGHT] = function ()
        p.setX(p.getX() + horizontal_speed)
        facing = RIGHT
    end

    controls[JUMP] = function (dt)
        -- even if the jump button is down, we don't
        -- want to run this function unless the player is jumping
        if not movement.is("jumping") then return end

        vertical_speed = math.max(vertical_speed - gravity, 0)

        p.setY(p.getY() - vertical_speed)

        if vertical_speed == 0 then
            entity.set(FALLING, true)
        end
    end

    controls[SHOOT] = function (dt)
    end

    local falling = function (dt)
        vertical_speed = math.min(vertical_speed + gravity, terminal_vertical_speed)

        p.setY(p.getY() + vertical_speed)

        if p.getY() > FLOOR_HEIGHT then
            entity.set(FALLING, false)
            p.setY(FLOOR_HEIGHT)
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

        if entity.get(FALLING) then
            falling(dt)
        end
    end

    entity.draw       = function ()
        local draw_x = p.getX() + width
        local draw_y = p.getY() - height

        love.graphics.setColor(COLOR.BLACK)
        if facing == LEFT then
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
        end

        if x_buster.is("pellet") or x_buster.is("cool_down") or x_buster.is("charging") then
            local offset = width

            if facing == LEFT then
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
