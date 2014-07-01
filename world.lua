
return function ()
    local entities = {}
    local timer    = 0
    local tic_duration = 5
    local background_image = love.graphics.newImage("assets/snow.png")

    local register = function (entity)
        entities[entity.get("id")] = entity
    end

    local unregister = function (entity)
        entities[entity.get("id")] = nil
        entity.cleanup()
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
            entity.update(dt)
        end

    end

    local draw = function (dt)
        love.graphics.draw(background_image)

        for i, entity in ipairs(entities) do
            entity.draw(dt)
        end
    end

    return {
        update   = update,
        draw     = draw,
        register = register
    }

end
