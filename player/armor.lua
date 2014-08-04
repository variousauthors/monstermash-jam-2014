
return function (entity, controls, verbose)
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)
    local armor                       = FSM(false, "move", entity.getName())
    local damaged_duration               = 30

    local FALLING   = "falling"
    local CAN_DASH  = "can_dash"
    local WALL_JUMP = "wall_jump"
    local AIR_DASH  = "air_dash"
    local SHOCKED   = "shocked"
    local DASH_JUMP = "dash_jump"

    armor.register_keys = { FALLING, CAN_DASH, WALL_JUMP, AIR_DASH, SHOCKED, DASH_JUMP }

    armor.addState({
        name = "inactive",
        init = function ()
            entity.set(SHOCKED, false)
        end
    })

    armor.addState({
        name = "destroyed",
        init = function()
            local id = entity.getId()
            Sound:stop(id)
            Sound:run("destroyed", id)

        end
    })

    armor.addState({
        name = "damaged",
        init = function ()
            local id = entity.getId()
            Sound:stop(id)
            Sound:run('damaged', id)
            entity.set("hp", math.max(entity.get("hp") - entity.get("damage_queue")))
            entity.set("damage_queue", 0)
            entity.set("invulnerable", 1)
            entity.set(DASH_JUMP, false)
            entity.set(SHOCKED, true)
        end,
    })

    armor.addTransition({
        from = "any",
        to = "damaged",
        condition = function ()
            return entity.get("hp") > 0 and entity.get("damage_queue") and entity.get("damage_queue") > 0
        end
    })

    armor.addTransition({
        from = "any",
        to = "destroyed",
        condition = function ()
            -- TODO this kind of check (for entity death_line stuff) should be done in the player update and flagged
            -- HP also
            return not armor.is('destroyed') and (entity.get("hp") < 1 or entity.getY() > entity.get("death_line"))
        end
    })

    armor.addTransition({
        from = "damaged",
        to = "inactive",
        condition = function ()
            return armor.getCount() > damaged_duration
        end
    })

    armor.start("inactive")

    return armor
end

