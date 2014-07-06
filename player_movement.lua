-- resolveLeft
-- resolveReft
-- resolveShoot
-- resolveFall
-- resolveDash
-- resolveJump

return function (entity, controls, verbose)
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)
    local movement                       = FSM(verbose)
    local dash_duration                  = 30
    local damaged_duration               = 20

    movement.addState({
        name = "standing",
        init = function ()
            entity.set("dash_jump", false)
            entity.set("shocked", false)
            entity.set("near_a_wall", nil)
        end
    })

    movement.addState({
        name = "running",
        update = function ()
            if entity.holding(LEFT) then
                entity.resolveLeft()
            end

            if entity.holding(RIGHT) then
                entity.resolveRight()
            end
        end
    })

    movement.addState({
        name = "dashing",
        update = function ()
            if entity.holding(DASH) then
                entity.resolveDash()
            end
        end
    })

    movement.addState({
        name = "dash_jump",
        init = function ()
            entity.set("dash_jump", true)
        end
    })

    movement.addState({
        name = "jumping",
        init = function ()
            -- if a jump starts near a wall, kick off
            if entity.get("near_a_wall") ~= nil then
                entity.set("wall_jump", true)
            end

            entity.startJump()
        end,
        update = function ()
            -- as long as you are holding jump, keep jumping
            if entity.holding(JUMP) then
                entity.resolveJump()
            end

            -- air control
            if entity.holding(LEFT) then
                entity.resolveLeft()
            end

            if entity.holding(RIGHT) then
                entity.resolveRight()
            end
        end
    })

    movement.addState({
        name = "falling",
        init = function ()
            entity.set("vs", 0)
            entity.set(FALLING, true)
        end,
        update = function ()
            if entity.holding(LEFT) then
                entity.resolveLeft()
            end

            if entity.holding(RIGHT) then
                entity.resolveRight()
            end
        end
    })

    movement.addState({
        name = "climbing",
        init = function ()
            entity.set("dash_jump", false)
        end,
        update = function ()
            if entity.holding(LEFT) then
                entity.resolveLeft()
            end

            if entity.holding(RIGHT) then
                entity.resolveRight()
            end

            -- megaman faces away from the wall
            local facing = entity.get("facing") == LEFT and RIGHT or LEFT
            entity.set("facing", facing)
        end
    })

    movement.addState({
        name = "wall_jump",
        init = function ()
            entity.set(FALLING, false)
            entity.set("wall_jump", true)
        end
    })

    movement.addState({
        name = "damaged",
        init = function ()
            entity.set("hp", math.max(entity.get("hp") - entity.get("damage_queue")))
            entity.set("damage_queue", 0)
            entity.set("invulnerable", 1)
            entity.set("dash_jump", false)
            entity.set("shocked", true)
        end
    })

    movement.addTransition({
        from = "standing",
        to = "running",
        condition = function ()
            return not entity.pressed(DASH) and not entity.pressed(JUMP) and (entity.holding(LEFT) or entity.holding(RIGHT))
        end
    })

    movement.addTransition({
        from = "standing",
        to = "falling",
        condition = function ()
            return entity.get("vs") > 0
        end
    })

    -- TODO add a from = "any" option to simplify this
    movement.addTransition({
        from = "standing",
        to = "jumping",
        condition = function ()
            return not entity.pressed(DASH) and entity.pressed(JUMP)
        end
    })

    movement.addTransition({
        from = "standing",
        to = "dashing",
        condition = function ()
            return entity.pressed(DASH)
        end
    })

    movement.addTransition({
        from = "running",
        to = "standing",
        condition = function ()
            return not entity.pressed(DASH) and not entity.holding(LEFT) and not entity.holding(RIGHT)
        end
    })

    movement.addTransition({
        from = "running",
        to = "jumping",
        condition = function ()

            return entity.pressed(JUMP)
        end
    })

    movement.addTransition({
        from = "running",
        to = "dashing",
        condition = function ()

            return entity.pressed(DASH)
        end
    })

    movement.addTransition({
        from = "running",
        to = "falling",
        condition = function ()
            return entity.get("vs") > 0
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "running",
        condition = function ()
            local turning     = (entity.get("facing") == LEFT and entity.pressed(RIGHT) or entity.get("facing") == RIGHT and entity.pressed(LEFT))
            local not_jumping = entity.holding(DASH) and not entity.pressed(JUMP)
            local dash_done   = movement.getCount() > dash_duration
            local running     = entity.pressed(RIGHT) or entity.pressed(LEFT)

            return not entity.get(FALLING) and ((dash_done and running) or (turning and not_jumping))
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "standing",
        condition = function ()
            local dash_done   = movement.getCount() > dash_duration
            local standing    = not entity.pressed(RIGHT) and not entity.pressed(LEFT)

            return (not entity.pressed(JUMP) and not entity.get(FALLING)) and (not entity.holding(DASH) or (dash_done and standing))
        end
    })

    -- rather than dashing to falling, we will do dashing to dash_jump
    -- but in a situation where you aren't jumping
    movement.addTransition({
        from = "dashing",
        to = "falling",
        condition = function ()

            return entity.get("vs") > 0
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "jumping",
        condition = function ()
            return entity.pressed(JUMP) and not entity.holding(LEFT) and not entity.holding(RIGHT)
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "dash_jump",
        condition = function ()
            return entity.pressed(JUMP) and (entity.holding(LEFT) or entity.holding(RIGHT))
        end
    })

    movement.addTransition({
        from = "jumping",
        to = "falling",
        condition = function ()
            return entity.get("vs") == 0 or not entity.holding(JUMP)
        end
    })

    movement.addTransition({
        from = "dash_jump",
        to = "jumping",
        condition = function ()
            return true
        end
    })

    movement.addTransition({
        from = "falling",
        to = "standing",
        condition = function ()
            return not entity.get(FALLING)
        end
    })

    movement.addTransition({
        from = "falling",
        to = "climbing",
        condition = function ()
            return movement.isSet("climbing") and entity.get(FALLING) and entity.get("vs") == 0
        end
    })

    movement.addTransition({
        from = "falling",
        to = "jumping",
        condition = function ()

            return entity.get("near_a_wall") ~= nil and entity.pressed(JUMP)
        end
    })


    movement.addTransition({
        from = "climbing",
        to = "standing",
        condition = function ()
            return not entity.get(FALLING)
        end
    })

    movement.addTransition({
        from = "climbing",
        to = "jumping",
        condition = function ()
            return entity.get(FALLING) and entity.pressed(JUMP)
        end
    })

    movement.addTransition({
        from = "climbing",
        to = "falling",
        condition = function ()
            local clinging = entity.get("facing") == LEFT and RIGHT or LEFT

            return entity.get(FALLING) and not entity.holding(clinging)
        end
    })

    movement.addTransition({
        from = "wall_jump",
        to = "jumping",
        condition = function ()
            return true
        end
    })

    movement.addTransition({
        from = "any",
        to = "damaged",
        condition = function ()
            return entity.get("damage_queue") and entity.get("damage_queue") > 0
        end
    })

    movement.addTransition({
        from = "damaged",
        to = "standing",
        condition = function ()
            return movement.getCount() > damaged_duration
        end
    })

    movement.start("standing")

    return movement
end

