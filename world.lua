
return function ()
    local entities = {}

    local register = function (entity)
        entities[entity.get("id")] = entity
    end

    local update = function (dt)
        -- iterate over the entities
        -- each of them that has queued a movement for this dt
        -- should try to move
        -- then resolve any collisions

        for i, entity in ipairs(entities) do
            if entity.willMove() then
                -- get the effect of the move from the entity,
                -- get the entity's current position
                -- try this move (including forces etc)
                -- if it works then update the player's position
            end
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
