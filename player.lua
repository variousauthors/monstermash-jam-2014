if not Entity then require("entity") end

LEFT         = "left"
RIGHT        = "right"
JUMP         = " "
FALLING      = "falling"
FLOOR_HEIGHT = 500

MovementModule = require("player_movement")

return function (x, y)
    local entity    = Entity()
    local p         = Point(x, y)
    local will_move = nil
    local maneuver  = nil
    local facing    = RIGHT

    local horizontal_speed = 6
    local vertical_speed   = 12
    local jump_height      = 200

    entity.setJumpOrigin = function ()
        entity.set("jump_origin", p.copy())
    end

    local movement  = MovementModule(entity)

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
        if movement.is("falling") then return end

        if p.getY() > entity.get("jump_origin").getY() - jump_height then
            p.setY(p.getY() - vertical_speed)
        else
            entity.set(JUMP, false)
        end
    end

    controls[FALLING] = function (dt)
        if p.getY() < FLOOR_HEIGHT then
            p.setY(p.getY() + vertical_speed)
        else
            entity.set(FALLING, false)
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

        for k, v in pairs(controls) do
            if entity.get(k) then
                v(dt)
            end
        end
    end

    local stand_in = 30
    entity.draw       = function ()
        love.graphics.setColor(COLOR.WHITE)
        if facing == LEFT then
            love.graphics.line(p.getX(), p.getY(), p.getX(), p.getY() + stand_in)
        else
            love.graphics.line(p.getX() + stand_in, p.getY(), p.getX() + stand_in, p.getY() + stand_in)
        end

        if movement.is("running") then
            love.graphics.setColor(COLOR.RED)
        elseif movement.is("jumping") or movement.is("falling") then
            love.graphics.setColor(COLOR.GREEN)
        else
            love.graphics.setColor(COLOR.BLUE)
        end

        love.graphics.rectangle("fill", p.getX(), p.getY(), stand_in, stand_in)
    end

    -- record the desired action of the player as a vector
    entity.keypressed = function (key)
        entity.set(key, true)
    end

    entity.keyreleased = function (key)
        entity.set(key, false)
    end

    return entity
end
