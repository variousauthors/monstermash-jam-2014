local anim8 = require("vendor/anim8/anim8")
local frames = require("animation_index")

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
        print("d:", duration)
        return timer > duration
    end

    animation.getInit = function (d, ...)
        local args = ...
        return function ()
            print(d)
            duration = d
            timer = 0
            print(animation.getState(), duration, args)
            anim = anim8.newAnimation(g(frames.get(animation.getState())), duration, args)
        end
    end

    animation.addState({
        name = "into_standing",
        init = animation.getInit(0.1, 'pauseAtEnd'),
        update = function (dt)
            local speed = 1

            timer = timer + speed*dt
            -- here we update the animation

            update_facing()
            anim:update(speed*dt)
        end
    })

    animation.addState({
        name = "standing",
        init = animation.getInit(0.1)
    })

    -- going into the jump animation
    animation.addState({
        name = "into_jumping",
        init = animation.getInit(0.2, 'pauseAtEnd'),
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
        init = animation.getInit(1)
    })

    -- going into falling
    animation.addState({
        name = "into_falling",
        init = animation.getInit(0.2, 'pauseAtEnd'),
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
        init = animation.getInit(0.1),
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
        to = "into_standing",
        condition = function ()
            return movement.is("standing")
        end
    })

    animation.addTransition({
        from = "into_standing",
        to = "standing",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.start("standing")

    return animation
end

