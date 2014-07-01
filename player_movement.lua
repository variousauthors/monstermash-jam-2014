
return function (entity)
    local movement = FSM()

    movement.addState({
        name = "running"
    })

    movement.addState({
        name = "standing"
    })

    movement.addState({
        name = "jumping",
        init = function ()
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
            return not entity.get(JUMP) and (entity.get(LEFT) or entity.get(RIGHT))
        end
    })

    -- TODO add a from = "any" option to simplify this
    movement.addTransition({
        from = "standing",
        to = "jumping",
        condition = function ()
            return entity.get(" ")
        end
    })

    movement.addTransition({
        from = "running",
        to = "standing",
        condition = function ()
            return not entity.get(LEFT) and not entity.get(RIGHT)
        end
    })

    movement.addTransition({
        from = "running",
        to = "jumping",
        condition = function ()
            return entity.get(JUMP)
        end
    })

    movement.addTransition({
        from = "jumping",
        to = "falling",
        condition = function ()
            return not entity.get(JUMP)
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

