if not Entity then require("entity") end

Entity = function ()
    local read_only  = {}
    read_only["id"]  = global.entity_id
    global.entity_id = global.entity_id + 1

    local get = function (key)
        return read_only[key]
    end

    return {
        get = get
    }
end

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
        if key == " " then
            will_move = true
        end
    end

    return entity
end
