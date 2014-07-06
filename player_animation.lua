local anim8 = require("vendor/anim8/anim8")

-- resolveLeft
-- resolveReft
-- resolveShoot
-- resolveFall
-- resolveDash
-- resolveJump

return function (entity, movement, x_buster, verbose)
    -- I think we won't need this
    -- local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)
    local animation                       = FSM(verbose)
    local dash_duration                  = 30
    local damaged_duration               = 20
    local timer = 0

    animation.isFinished = function ()
        return timer > 1
    end

    animation.addState({
        name = "standing",
        init = function ()
            print("standing")
        end
    })

    -- going into the jump animation
    animation.addState({
        name = "into_jumping",
        init = function ()
            print("into_jumping")
            timer = 0
        end,
        update = function (dt)
            local speed = 1

            -- if megaman is already falling, run to catch up
            if movement.is("falling") then
                speed = entity.get("initial_vs") / entity.get("vs")
            end

            timer = timer + speed*dt
            -- here we update the animation
            print(timer)
        end
    })

    -- the apex of the jump, a single
    -- frame played forever
    animation.addState({
        name = "jumping",
        init = function ()
            print("jumping")
        end,
    })

    -- going into falling
    animation.addState({
        name = "into_falling",
        init = function ()
            print("into_falling")
            timer = 0
        end,
        update = function (dt)
            local speed = 1

            -- if megaman is already standing, run to catch up
            if movement.is("standing") then
                speed =  entity.get("initial_vs") / entity.get("vs")
            end

            timer = timer + speed*dt
            -- here we update the animation
            print(timer)
        end
    })

    -- peak falling
    animation.addState({
        name = "falling",
        init = function ()
            print("falling")
        end,
    })

    animation.addTransition({
        from = "standing",
        to = "into_jumping",
        condition = function ()
            return movement.is("jumping")
        end
    })

    animation.addTransition({
        from = "into_jumping",
        to = "jumping",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "jumping",
        to = "into_falling",
        condition = function ()
            return movement.is("falling")
        end
    })

    animation.addTransition({
        from = "into_falling",
        to = "falling",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "falling",
        to = "standing",
        condition = function ()
            return movement.is("standing")
        end
    })

    animation.start("standing")

    return animation
end

