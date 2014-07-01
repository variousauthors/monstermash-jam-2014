
return function ()
    local entities = {}
    local timer    = 0
    local tic_duration = 5

    local register = function (entity)
        entities[entity.get("id")] = entity
    end

    local tic = function (dt)
        timer = timer + dt

        if timer > tic_duration then
            for i, entity in ipairs(entities) do
                entity.tic()
            end

            timer = 0
        end
    end

    local update = function (dt)
        tic(dt)

        -- iterate over the entities
        -- each of them that has queued a movement for this dt
        -- should try to move
        -- then resolve any collisions

        for i, entity in ipairs(entities) do
            entity.update(dt, timer)
        end
    end

    local draw = function (dt)

    end

    return {
        update   = update,
        draw     = draw,
        register = register
    }

end
