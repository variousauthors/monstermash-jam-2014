
return function (entity)
    local movement = FSM()
    local dash_duration = 30

    movement.addState({
        name = "standing",
        init = function ()
            entity.set("dash_jump", false)
        end
    })

    movement.addState({
        name = "running"
    })

    movement.addState({
        name = "dashing"
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
            entity.startJump()
            entity.setJumpOrigin()
        end
    })

    movement.addState({
        name = "falling",
        init = function ()
            entity.set(FALLING, true)
        end
    })

    movement.addTransition({
        from = "standing",
        to = "running",
        condition = function ()
            return not entity.pressed(DASH) and not entity.pressed(JUMP) and (entity.holding(LEFT) or entity.holding(RIGHT))
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

            return not entity.get(FALLING) and (not entity.holding(DASH) or (dash_done and standing))
        end
    })

    -- rather than dashing to falling, we will do dashing to dash_jump
    -- but in a situation where you aren't jumping
    movement.addTransition({
        from = "dashing",
        to = "falling",
        condition = function ()
            entity.set("dash_jump", true)

            return entity.get("vs") > 0
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "jumping",
        condition = function ()
            return entity.holding(DASH) and entity.pressed(JUMP) and not entity.holding(LEFT) and not entity.holding(RIGHT)
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "dash_jump",
        condition = function ()
            return entity.holding(DASH) and entity.pressed(JUMP) and (entity.holding(LEFT) or entity.holding(RIGHT))
        end
    })

    movement.addTransition({
        from = "jumping",
        to = "falling",
        condition = function ()
            return entity.get(FALLING) or not entity.holding(JUMP)
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

    movement.start("standing")

    return movement
end

