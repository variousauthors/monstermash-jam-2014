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
    local animation        = FSM(true, "animation")
    local timer            = 0
    local anim, duration
    local facing = entity.get("facing")

    local g = anim8.newGrid(51, 51, image:getWidth(), image:getHeight())

    local update_facing = function ()
        facing = entity.get("facing")

        anim:setFlipped(facing == LEFT)
    end

    local _old = anim8.newAnimation
    anim8.newAnimation = function (frames, durations, onLoop)
        local result = _old(frames, durations, onLoop)

        facing = entity.get("facing")

        result:setFlipped(facing == LEFT)

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

    animation.getInit = function (d, ...)
        local args = ...
        return function ()
            duration, timer = d, 0
            anim = anim8.newAnimation(g(frames.get(animation.getState())), duration, args)
        end
    end

    update_transition_animation = function (dt)
        local speed = 1

        timer = timer + speed*dt
        -- here we update the animation

        update_facing()
        anim:update(speed*dt)
    end

    --- ANIMATION STATES ---

    animation.addState({
        name = "standing",
        init = animation.getInit(0.1)
    })

    animation.addState({
        name = "to_recoil",
        init = animation.getInit(0.1)
    })

    animation.addState({
        name = "recoil",
        init = animation.getInit(0.1)
    })

    -- going into the jump animation
    animation.addState({
        name = "to_jumping",
        init = animation.getInit(0.1, 'pauseAtEnd'),
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
        name = "to_falling",
        init = animation.getInit(0.25, 'pauseAtEnd'),
        update = function (dt)
            local speed = 1

            -- if megaman is already standing, run to catch up
            if movement.is("standing") then
                speed =  entity.get("initial_vs") / entity.get("vs")
            end

            if movement.is("climbing") then
                speed = 3
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

    animation.addState({
        name = "falling_to_standing",
        init = animation.getInit(0.2, 'pauseAtEnd'),
        update = update_transition_animation
    })

    animation.addState({
        name = "to_running",
        init = animation.getInit(0.1, 'pauseAtEnd'),
        update = update_transition_animation
    })

    animation.addState({
        name = "running",
        init = animation.getInit(0.06),
    })

    animation.addState({
        name = "from_running",
        init = animation.getInit(0.1, 'pauseAtEnd'),
        update = update_transition_animation
    })

    animation.addState({
        name = "to_dashing",
        init = animation.getInit(0.1, 'pauseAtEnd'),
        update = update_transition_animation
    })

    animation.addState({
        name = "dashing",
        init = animation.getInit(0.1),
    })

    animation.addState({
        name = "from_dashing",
        init = animation.getInit(0.1, 'pauseAtEnd'),
        update = update_transition_animation
    })

    animation.addState({
        name = "to_climbing",
        init = animation.getInit(0.1, 'pauseAtEnd'),
        update = update_transition_animation
    })

    animation.addState({
        name = "climbing",
        init = animation.getInit(0.1),
    })

    animation.addState({
        name = "climbing_to_jump",
        init = animation.getInit(0.1, 'pauseAtEnd'),
        update = update_transition_animation
    })

    animation.addState({
        name = "to_hurt",
        init = animation.getInit(0.1, 'pauseAtEnd'),
        update = update_transition_animation
    })

    animation.addState({
        name = "hurt",
        init = animation.getInit(0.2, 'pauseAtEnd'),
        update = update_transition_animation
    })

    animation.addState({
        name = "death",
        init = animation.getInit(1, 'pauseAtEnd'),
    })

    --- TRANSITIONS ---

    animation.addTransition({
        from = "standing",
        to = "to_jumping",
        condition = function ()
            return movement.is("jumping")
        end
    })

    animation.addTransition({
        from = "standing",
        to = "to_dashing",
        condition = function ()
            return movement.is("dashing")
        end
    })

    animation.addTransition({
        from = "standing",
        to = "to_running",
        condition = function ()
            return movement.is("running")
        end
    })

    animation.addTransition({
        from = "standing",
        to = "to_falling",
        condition = function ()
            return movement.is("falling")
        end
    })

    animation.addTransition({
        from = "standing",
        to = "to_recoil",
        condition = function ()
            return movement.is("standing") and x_buster.is("shoot")
        end
    })

    animation.addTransition({
        from = "recoil",
        to = "to_recoil",
        condition = function ()
            return movement.is("standing") and x_buster.is("cool_down")
        end
    })

    animation.addTransition({
        from = "recoil",
        to = "standing",
        condition = function ()
            return movement.is("standing") and x_buster.is("inactive")
        end
    })

    animation.addTransition({
        from = "to_jumping",
        to = "jumping",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "to_jumping",
        to = "to_falling",
        condition = function ()
            return movement.is("falling")
        end
    })

    animation.addTransition({
        from = "to_jumping",
        to = "to_dashing",
        condition = function ()
            return not animation.isFinished() and movement.is("dashing")
        end
    })

    animation.addTransition({
        from = "jumping",
        to = "to_falling",
        condition = function ()
            return movement.is("falling")
        end
    })

    animation.addTransition({
        from = "jumping",
        to = "to_climbing",
        condition = function ()
            return movement.is("climbing")
        end
    })

    animation.addTransition({
        from = "jumping",
        to = "climbing_to_jump",
        condition = function ()
            return movement.is("jumping") and entity.get("wall_jump")
        end
    })

    animation.addTransition({
        from = "jumping",
        to = "to_dashing",
        condition = function ()
            return movement.is("dashing")
        end
    })

    animation.addTransition({
        from = "to_falling",
        to = "falling",
        condition = function ()
            return (animation.isFinished() or movement.is("standing") or movement.is("running")) and not movement.is("climbing")
        end
    })

    animation.addTransition({
        from = "to_falling",
        to = "climbing_to_jump",
        condition = function ()
            return movement.is("wall_jump")
        end
    })

    animation.addTransition({
        from = "to_falling",
        to = "to_climbing",
        condition = function ()
            return animation.isFinished() and movement.is("climbing")
        end
    })

    animation.addTransition({
        from = "to_falling",
        to = "to_dashing",
        condition = function ()
            return movement.is("dashing")
        end
    })

    animation.addTransition({
        from = "falling",
        to = "falling_to_standing",
        condition = function ()
            return movement.is("standing")
        end
    })

    animation.addTransition({
        from = "falling_to_standing",
        to = "standing",
        condition = function ()
            return animation.isFinished() and not movement.is("jumping")
        end
    })

    animation.addTransition({
        from = "falling_to_standing",
        to = "to_jumping",
        condition = function ()
            return movement.is("jumping")
        end
    })

    animation.addTransition({
        from = "falling",
        to = "to_jumping",
        condition = function ()
            return movement.is("jumping")
        end
    })

    animation.addTransition({
        from = "falling",
        to = "to_dashing",
        condition = function ()
            return movement.is("dashing")
        end
    })

    animation.addTransition({
        from = "falling",
        to = "running",
        condition = function ()
            return movement.is("running")
        end
    })

    animation.addTransition({
        from = "falling",
        to = "to_climbing",
        condition = function ()
            return movement.is("climbing")
        end
    })

    animation.addTransition({
        from = "falling",
        to = "climbing_to_jump",
        condition = function ()
            return movement.is("wall_jump")
        end
    })

    animation.addTransition({
        from = "to_running",
        to = "running",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "running",
        to = "from_running",
        condition = function ()
            return movement.is("standing")
        end
    })

    animation.addTransition({
        from = "from_running",
        to = "standing",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "from_running",
        to = "running",
        condition = function ()
            return movement.is("running")
        end
    })

    animation.addTransition({
        from = "running",
        to = "to_jumping",
        condition = function ()
            return movement.is("jumping")
        end
    })

    animation.addTransition({
        from = "running",
        to = "to_dashing",
        condition = function ()
            return movement.is("dashing")
        end
    })

    animation.addTransition({
        from = "running",
        to = "to_falling",
        condition = function ()
            return movement.is("falling")
        end
    })

    animation.addTransition({
        from = "to_dashing",
        to = "dashing",
        condition = function ()
            return animation.isFinished() or movement.is("dashing")
        end
    })

    animation.addTransition({
        from = "to_dashing",
        to = "jumping",
        condition = function ()
            return animation.isFinished() or movement.is("jumping")
        end
    })

    animation.addTransition({
        from = "to_dashing",
        to = "standing",
        condition = function ()
            return animation.isFinished() or movement.is("standing")
        end
    })

    animation.addTransition({
        from = "to_dashing",
        to = "running",
        condition = function ()
            return animation.isFinished() or movement.is("running")
        end
    })

    animation.addTransition({
        from = "to_dashing",
        to = "falling",
        condition = function ()
            return animation.isFinished() or movement.is("falling")
        end
    })

    animation.addTransition({
        from = "dashing",
        to = "from_dashing",
        condition = function ()
            return movement.is("standing")
        end
    })

    animation.addTransition({
        from = "from_dashing",
        to = "standing",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "dashing",
        to = "to_jumping",
        condition = function ()
            return movement.is("jumping")
        end
    })

    animation.addTransition({
        from = "dashing",
        to = "to_running",
        condition = function ()
            return movement.is("running")
        end
    })

    animation.addTransition({
        from = "dashing",
        to = "to_falling",
        condition = function ()
            return movement.is("falling")
        end
    })

    animation.addTransition({
        from = "to_climbing",
        to = "climbing",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "to_climbing",
        to = "climbing_to_jump",
        condition = function ()
            return movement.is("wall_jump")
        end
    })

    animation.addTransition({
        from = "climbing",
        to = "to_dashing",
        condition = function ()
            return movement.is("dashing")
        end
    })

    animation.addTransition({
        from = "climbing",
        to = "to_falling",
        condition = function ()
            return movement.is("falling")
        end
    })

    animation.addTransition({
        from = "climbing",
        to = "standing",
        condition = function ()
            return movement.is("standing")
        end
    })

    animation.addTransition({
        from = "climbing",
        to = "climbing_to_jump",
        condition = function ()
            return movement.is("wall_jump")
        end
    })

    animation.addTransition({
        from = "climbing_to_jump",
        to = "jumping",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "any",
        to = "to_hurt",
        condition = function ()
            return movement.is("damaged")
        end
    })

    animation.addTransition({
        from = "to_hurt",
        to = "hurt",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "hurt",
        to = "standing",
        condition = function ()
            return animation.isFinished()
        end
    })

    animation.addTransition({
        from = "any",
        to = "death",
        condition = function ()
            return movement.is("destroyed")
        end
    })

    animation.start("standing")

    return animation
end

