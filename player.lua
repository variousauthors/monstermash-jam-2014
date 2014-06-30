global.entity_id = 1

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
