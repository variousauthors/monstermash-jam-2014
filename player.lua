if not Entity then require("entity") end

LEFT  = 0
RIGHT = 1

return function (x, y)
    local entity    = Entity()
    local p         = Point(x, y)
    local will_move = nil
    local maneuver  = nil
    local facing    = RIGHT
    local movement  = FSM()

    movement.addState({
        name = "running"
    })

    movement.addState({
        name = "standing"
    })

    movement.addTransition({
        from = "standing",
        to = "running",
        condition = function ()
            return entity.get("left") or entity.get("right")
        end
    })

    movement.addTransition({
        from = "running",
        to = "standing",
        condition = function ()
            return not entity.get("left") and not entity.get("right")
        end
    })

    movement.start("standing")

    local controls = {
        left  = function ()
            p.setX(p.getX() - 10)
            facing = LEFT
        end,
        right = function ()
            p.setX(p.getX() + 10)
            facing = RIGHT
        end
    }

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

    entity.draw       = function ()
        love.graphics.setColor(COLOR.WHITE)
        if facing == LEFT then
            love.graphics.line(p.getX(), p.getY(), p.getX(), p.getY() + 10)
        else
            love.graphics.line(p.getX() + 10, p.getY(), p.getX() + 10, p.getY() + 10)
        end

        if movement.is("running") then
            love.graphics.setColor(COLOR.RED)
        else
            love.graphics.setColor(COLOR.BLUE)
        end

        love.graphics.rectangle("fill", p.getX(), p.getY(), 10, 10)
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
