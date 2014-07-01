if not Entity then require("entity") end

return function (x, y)
    local entity = Entity()
    local p      = Point(x, y)
    local move   = nil

    entity.update     = function (dt)
        move = nil
    end

    entity.draw       = function () end

    -- record the desired action of the player as a vector
    entity.keypressed = function (key)
        if key == " " then
            move = Vector(1, 1)
        end
    end

    entity.willMove = function ()
        return move ~= nil
    end

    return entity
end
