local anim8 = require("vendor/anim8/anim8")

-- resolveLeft
-- resolveReft
-- resolveShoot
-- resolveFall
-- resolveDash
-- resolveJump

return function (entity, image, movement, x_buster, controls, verbose)
    -- I think we won't need this
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)
    local animation        = FSM(verbose)
    local timer            = 0
    local anim, duration
    local facing = entity.get("facing")

    local g = anim8.newGrid(51, 51, image:getWidth(), image:getHeight())

    local update_facing = function ()
        local old = facing
        facing = entity.get("facing")

        if old ~= facing then
            anim:flipH()
        end
    end

    local _old = anim8.newAnimation
    anim8.newAnimation = function (a, b)
        local result = _old(a, b)

        if entity.get("facing") == LEFT then
            result:flipH()
        end

        return result
    end

    -- by default the state updates will just update the
    -- animation (after any transitions etc)
    local _update = animation.update
    animation.update = function (dt)
        _update(dt)
        update_facing()
        anim:update(dt)
    end

    animation.draw = function (x, y)
        anim:draw(image, x, y)
    end

    animation.isFinished = function ()
        return timer > duration
    end

    animation.addState({
        name = "standing",
        init = function ()
            anim = anim8.newAnimation(g(1, 1), 0.1)
        end
    })

    -- going into the jump animation
    animation.addState({
        name = "into_jumping",
        init = function ()
            duration = 0.2
            anim = anim8.newAnimation(g('2-4',1), duration, 'pauseAtEnd')
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

            update_facing()
            anim:update(speed*dt)
        end
    })

    -- the apex of the jump, a single
    -- frame played forever
    animation.addState({
        name = "jumping",
        init = function ()
            anim = anim8.newAnimation(g(4,1), 1, 'pauseAtEnd')
        end,
    })

    -- going into falling
    animation.addState({
        name = "into_falling",
        init = function ()
            duration = 0.2
            anim = anim8.newAnimation(g('4-5',1), duration, 'pauseAtEnd')
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

            update_facing()
            anim:update(speed*dt)
        end
    })

    -- peak falling
    animation.addState({
        name = "falling",
        init = function ()
            anim = anim8.newAnimation(g(6,1), 0.1)
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
            return not movement.is("falling")
        end
    })

    animation.start("standing")

    return animation
end

