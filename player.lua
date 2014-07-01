if not Entity then require("entity") end

LEFT  = 0
RIGHT = 1
SPACE = " "

return function (x, y)
    local entity    = Entity()
    local p         = Point(x, y)
    local will_move = nil
    local maneuver  = nil
    local facing    = RIGHT
    local movement  = FSM()

    local horizontal_speed = 3
    local vertical_speed   = 12
    local jump_origin
    local jump_height      = 200

    movement.addState({
        name = "running"
    })

    movement.addState({
        name = "standing"
    })

    movement.addState({
        name = "jumping",
        init = function ()
            jump_origin = p.copy()
        end
    })

    movement.addState({
        name = "falling",
        init = function ()
            entity.set("falling", true)
        end
    })

    movement.addTransition({
        from = "standing",
        to = "running",
        condition = function ()
            return not entity.get(" ") and (entity.get("left") or entity.get("right"))
        end
    })

    -- TODO add a from = "any" option to simplify this
    movement.addTransition({
        from = "standing",
        to = "jumping",
        condition = function ()
            return entity.get(" ")
        end
    })

    movement.addTransition({
        from = "running",
        to = "standing",
        condition = function ()
            return not entity.get("left") and not entity.get("right")
        end
    })

    movement.addTransition({
        from = "running",
        to = "jumping",
        condition = function ()
            return entity.get(" ")
        end
    })

    movement.addTransition({
        from = "jumping",
        to = "falling",
        condition = function ()
            return not entity.get(" ")
        end
    })

    movement.addTransition({
        from = "falling",
        to = "standing",
        condition = function ()
            return not entity.get("falling")
        end
    })

    movement.start("standing")

    local controls = {}
    controls["left"] = function ()
        p.setX(p.getX() - horizontal_speed)
        facing = LEFT
    end

    controls["right"] = function ()
        p.setX(p.getX() + horizontal_speed)
        facing = RIGHT
    end

    controls[" "] = function (dt)
        if p.getY() > jump_origin.getY() - jump_height then
            p.setY(p.getY() - vertical_speed)
        else
            entity.set(" ", false)
        end
    end

    controls["falling"] = function (dt)
        if p.getY() < jump_origin.getY() then
            p.setY(p.getY() + vertical_speed)
        else
            entity.set("falling", false)
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
