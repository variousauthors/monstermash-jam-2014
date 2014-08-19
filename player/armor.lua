
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

    -- animation info for destroy
    local ring_timer       = 0
    local ring_timer_limit = 100
    local ring_count       = 1
    local ring_speed       = 40
    local ring_limit       = 2

    local bulletFilter = function (other)
        return other.get and other.get("isBullet") == true and other.get("owner_id") ~= entity.get("id")
    end

    entity.set("damage_queue", 0)

    local resolveBulletCollide = function ()
        local x, y = entity.getX(), entity.getY()
        local cols, len = entity.bump_check(entity, x, y, bulletFilter)

        while len > 0 and not (entity.get("damage_queue") > 0) do
            local col            = cols[1]
            local bullet         = col.other
            local tx, ty, nx, ny = col:getTouch()

            local entity_center = entity.getX() + col.itemRect.w/2
            local bullet_center = bullet.getX() + col.otherRect.w/2
            local facing        = (entity_center > bullet_center) and LEFT or RIGHT

            entity.set("damage_queue", bullet.get("damage"))
            entity.setFacing(facing)

            -- if there is something the bullet needs to do
            if bullet.resolveEntityCollide then
                bullet.resolveEntityCollide()
            end

            cols, len = entity.bump_check(entity, x, y, bulletFilter)
        end
    end

    armor.register_keys = { FALLING, CAN_DASH, WALL_JUMP, AIR_DASH, SHOCKED, DASH_JUMP }

    armor.addState({
        name = "inactive",
        init = function ()
            entity.set(SHOCKED, false)
        end,
        update = resolveBulletCollide
    })

    armor.addState({
        name = "destroyed",
        init = function()
            local id = entity.getId()
            Sound:stop(id)
            Sound:run("destroyed", id)

        end,
        update = function (dt)
            if ring_count < ring_limit then
                ring_count = ring_count + 1
            end

            -- remove from the world
            entity.remove()

            ring_timer = ring_timer + ring_speed*dt
            if ring_timer > ring_timer_limit then

                -- unregister as an entity
                entity._unregister()
            end
        end,
        draw = function ()
            local draw_x = entity.getX()
            local draw_y = entity.getY()

            love.graphics.setColor(COLOR.CYAN)
            for j = 1, ring_count do
                local r = ring_timer/j

                for i = 1, 8 do
                    local rad = i*math.pi/4 + ring_timer
                    local x = r*4*math.cos(rad)
                    local y = r*4*math.sin(rad)

                    local rad2 = i*math.pi/4 + ring_timer + math.pi/3
                    local x2 = r*4.2*math.cos(rad2)
                    local y2 = r*4.2*math.sin(rad2)

                    love.graphics.rectangle("fill", draw_x + x, draw_y + y, 5, 5)
                    love.graphics.rectangle("fill", draw_x + x2, draw_y + y2, 5, 5)
                end
            end
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

