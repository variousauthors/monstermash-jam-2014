if not Entity then require("entity") end

return function (x, y)
    local entity    = Entity()
    local p         = Point(x, y)
    local will_move = nil
    local maneuver  = nil

    local willMove = function ()
        return will_move ~= nil
    end

    -- every tick, set the current maneuver
    entity.tic = function ()
        if willMove() then
            will_move = nil
        end
    end

    entity.update     = function (dt, timer)
    end

    entity.draw       = function ()
        love.graphics.setColor(COLOR.BLUE)
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
