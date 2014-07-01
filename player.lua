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
    local shooting  = false

    local local_scale = 3

    -- back of glove to beginning of red thing
    -- red thing is top
    local height = 30 * local_scale
    local width  = 15  * local_scale

    local jump_origin
    local horizontal_speed        = 1.5  * local_scale
    local initial_vertical_speed  = 5    * local_scale
    local terminal_vertical_speed = 5.75 * local_scale
    local vertical_speed          = 0    * local_scale
    local gravity                 = 0.25 * local_scale

    entity.setJumpOrigin = function ()
        jump_origin = p.copy()
    end

    entity.startJump = function ()
        vertical_speed = initial_vertical_speed
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

        vertical_speed = math.max(vertical_speed - gravity, 0)

        p.setY(p.getY() - vertical_speed)

        if vertical_speed == 0 then
            entity.set(JUMP, false)
        end
    end

    controls[FALLING] = function (dt)
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

        for k, v in pairs(controls) do
            if entity.get(k) then
                v(dt)
            end
        end
    end

    local stand_in = 30
    entity.draw       = function ()
        love.graphics.setColor(COLOR.BLACK)
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
        love.graphics.setColor(COLOR.WHITE)
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
