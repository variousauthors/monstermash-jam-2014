
local SmokeTrail = require("decorations/smoke_trail")
local DashSparks = require("decorations/dash_sparks")

local smoke_dimension = SmokeTrail.WIDTH
local sparks_width    = DashSparks.WIDTH
local sparks_height   = DashSparks.HEIGHT

-- TODO assert that entity has the right interface
-- TODO better would be to pass in an object that only
-- exposes those methods: then we can do "if and only if"
-- entity must implement
-- set/get for boolean flags only
-- pressed/holding
-- getFacing/setFacing
-- getId/getName

return function (entity, controls)
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)

    local movement       = FSM(false, "move", entity.getName())
    local dash_duration  = 30
    local dash_speed     = 3.5
    local smoke_interval = 4

    -- these could be global
    local gravity          = 0.25
    local terminal_vs      = 5.75
    local horizontal_speed = 1.5
    local initial_vs       = 5

    -- TODO this represents coupling between the animation
    -- module and the movement module. The animation module
    -- needs initial_vs to know how fast to run the falling
    -- animation
    entity.set("initial_vs", initial_vs)

    local FALLING   = "falling"
    local CAN_DASH  = "can_dash"
    local WALL_JUMP = "wall_jump"
    local AIR_DASH  = "air_dash"
    local SHOCKED   = "shocked"
    local DASH_JUMP = "dash_jump"

    movement.move = function (direction, speed)
        local sign = (direction == LEFT) and -1 or 1

        if entity.get(DASH_JUMP) then
            speed = dash_speed
        end

        -- TODO #1 this releases the dash key
        -- everything seems to work fine if we comment
        -- out this line, but the replays show a diff
        entity.set(DASH, false)

        entity.adjustX(sign*speed)
    end

    movement.resolveFall = function (dt)
        if movement.is("wall_jump") or movement.is('jumping') then return end

        entity.setDeltaY(math.min(entity.getDeltaY() + gravity, terminal_vs))

        entity.adjustY(entity.getDeltaY())
    end

    local resolveDash = function (dt)
        local speed = horizontal_speed*2
        local sign = 1

        if entity.getFacing() == LEFT then sign = -1 end

        entity.adjustX(sign*speed)
    end


    local resolveLeft = function ()
        movement.move(LEFT, horizontal_speed)

        if not entity.holding(RIGHT) then
            entity.setFacing(LEFT)
        end
    end

    local resolveRight = function ()
        movement.move(RIGHT, horizontal_speed)

        if not entity.holding(LEFT) then
            entity.setFacing(RIGHT)
        end
    end

    local resolveJump = function (dt)
        local result

        if entity.get(WALL_JUMP) then
            local away = entity.getFacingWall() == LEFT and RIGHT or LEFT

            movement.move(away, 1)

            entity.setFacing(entity.getFacingWall())

            -- removed this while fixing wall jump: we'll set near a wall to nil when the
            -- player's senses are not colliding with a wall
            -- entity.set("near_a_wall", nil)
        end

        result = -entity.getDeltaY()
        entity.setDeltaY(math.max(entity.getDeltaY() - gravity, 0))

        entity.adjustY(result)
    end

    movement.register_keys = { FALLING, CAN_DASH, WALL_JUMP, AIR_DASH, SHOCKED, DASH_JUMP }

    movement.addState({
        name = "standing",
        init = function ()
            entity.set(DASH_JUMP, false)
            entity.set(SHOCKED, false)
            entity.setFacingWall(nil)
            entity.set(CAN_DASH, true)
            entity.set(AIR_DASH, false)
        end
    })

    movement.addState({
        name = "shocked"
    })

    movement.addState({
        name = "running",
        init = function ()
            entity.set(DASH_JUMP, false)
            entity.set(CAN_DASH, true)
            entity.set(AIR_DASH, false)
        end,
        -- TODO this is the kind of function I'd ilke
        -- to set in the player, and use the closure
        -- property
        update = function ()
            if entity.holding(LEFT) then
                resolveLeft()
            end

            if entity.holding(RIGHT) then
                resolveRight()
            end
        end
    })

    movement.addState({
        name = "dashing",
        init = function()
            entity.set(CAN_DASH, false)
            local id = entity.getId()
            Sound:run('dash', id)

        end,
        update = function ()
            if entity.holding(DASH) then
                resolveDash()
                local facing = entity.getFacing() == LEFT and RIGHT or LEFT
                local sign = ( facing == RIGHT ) and 1 or -1

                if movement.getCount() == 2 then
                    entity.register(DashSparks(entity.getX() + sign*(sparks_width), entity.getY() + entity.getHeight(), entity))
                end

                if movement.getCount() % smoke_interval == 0 then

                    entity.register(SmokeTrail(entity.getX() + sign*(1.8*smoke_dimension), entity.getY() + entity.getHeight(), entity))
                end
            end
        end
    })

    movement.addState({
        name = "dash_jump",
        init = function ()
            entity.set(CAN_DASH, false)
            local id = entity.getId()
            Sound:run(WALL_JUMP, id)
            entity.set(DASH_JUMP, true)
        end
    })

    movement.addState({
        name = "air_dash",
        init = function ()
            entity.set(CAN_DASH, false)
            local id = entity.getId()
            Sound:run('dash', id)
            entity.set(AIR_DASH, true)
        end
    })

    movement.addState({
        name = "jumping",
        init = function ()
            local id = entity.getId()

            -- if a jump starts near a wall, kick off
            entity.set(WALL_JUMP, false)
            Sound:run('jump', id)

            -- if we are continuing from a wall jump there
            -- is no need to reset this
            if entity.getDeltaY() == 0 then
                entity.setDeltaY(initial_vs)
            end
        end,
        update = function ()
            -- as long as you are holding jump, keep jumping
            if entity.holding(JUMP) then
                resolveJump()
            end

            -- air control
            if entity.holding(LEFT) then
                resolveLeft()
            end

            if entity.holding(RIGHT) then
                resolveRight()
            end
        end
    })

    movement.addState({
        name = "wall_jump",
        init = function ()
            local id = entity.getId()
            entity.set(WALL_JUMP, true)

            entity.setFacing(entity.getFacingWall())
            Sound:run(WALL_JUMP, id)

            entity.set(FALLING, false)

            entity.setDeltaY(initial_vs)
        end,
        update = function ()
            -- wall jump can't be interrupted or air controlled
            resolveJump()
        end
    })

    movement.addState({
        name = "falling",
        init = function ()
            entity.setDeltaY(0)
            entity.set(FALLING, true)
        end,
        update = function ()
            if entity.holding(LEFT) then
                resolveLeft()
            end

            if entity.holding(RIGHT) then
                resolveRight()
            end
        end
    })

    movement.addState({
        name = "climbing",
        init = function ()
            entity.set(DASH_JUMP, false)
            entity.set(CAN_DASH, true)
        end,
        update = function ()
            if entity.holding(LEFT) then
                resolveLeft()
            end

            if entity.holding(RIGHT) then
                resolveRight()
            end

            -- megaman faces away from the wall
            local facing = entity.getFacing() == LEFT and RIGHT or LEFT
            entity.setFacing(facing)

            if movement.getCount() > 8 and movement.getCount() % (1.5*smoke_interval) == 0 then
                local offset = math.sin(5*movement.getCount())
                local sign = ( facing == RIGHT ) and 1 or -1

                entity.register(SmokeTrail(entity.getX() + sign*(offset - smoke_dimension), entity.getY() + entity.getHeight() - smoke_dimension, entity))
            end
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
            return entity.getDeltaY() > 0 and not (entity.holding(LEFT) or entity.holding(RIGHT))
        end
    })

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
            return entity.pressed(DASH) and entity.get(CAN_DASH)
        end
    })

    movement.addTransition({
        from = "running",
        to = "standing",
        condition = function ()
            local running    = (entity.holding(LEFT) or entity.holding(RIGHT))
            local turning    = (entity.pressed(RIGHT) or entity.pressed(LEFT))

            return not entity.pressed(DASH) and (not running or press_both) and not turning and entity.getDeltaY() == 0
        end
    })

    movement.addTransition({
        from = "running",
        to = "jumping",
        condition = function ()

            return entity.pressed(JUMP) and entity.getDeltaY() == 0
        end
    })

    movement.addTransition({
        from = "running",
        to = "dashing",
        condition = function ()

            return entity.pressed(DASH) and entity.get(CAN_DASH)
        end
    })

    movement.addTransition({
        from = "running",
        to = "falling",
        condition = function ()
            return entity.getDeltaY() > 0 and not entity.pressed(DASH)
        end
    })

    movement.addTransition({
        from = "air_dash",
        to = "dashing",
        condition = function ()
            return true
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "running",
        condition = function ()
            local turning     = (entity.getFacing() == LEFT and entity.pressed(RIGHT) or entity.getFacing() == RIGHT and entity.pressed(LEFT))
            local not_jumping = not entity.holding(JUMP) and not entity.pressed(JUMP)
            local dash_done   = movement.getCount() > dash_duration or not entity.holding(DASH)
            local running     = entity.holding(RIGHT) or entity.holding(LEFT)

            return not movement.isSet("would_fall") and ((dash_done and running) or turning)
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "standing",
        condition = function ()
            local turning     = (entity.getFacing() == LEFT and entity.pressed(RIGHT) or entity.getFacing() == RIGHT and entity.pressed(LEFT))
            local not_jumping = not entity.holding(JUMP) and not entity.pressed(JUMP)
            local dash_done   = movement.getCount() > dash_duration or not entity.holding(DASH)
            local running     = entity.holding(RIGHT) or entity.holding(LEFT)

            return not movement.isSet("would_fall") and dash_done and not (running or turning)
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "falling",
        condition = function ()
            local turning   = (entity.getFacing() == LEFT and entity.pressed(RIGHT) or entity.getFacing() == RIGHT and entity.pressed(LEFT))
            local dash_done = movement.getCount() > dash_duration or not entity.holding(DASH)

            return movement.isSet("would_fall") and (dash_done or turning)
        end
    })

    movement.addTransition({
        from = "dashing",
        to = "dash_jump",
        condition = function ()
            return entity.pressed(JUMP) and not entity.get(AIR_DASH)
        end
    })

    movement.addTransition({
        from = "jumping",
        to = "falling",
        condition = function ()
            return not entity.pressed(DASH) and (entity.getDeltaY() == 0 or not entity.holding(JUMP) and not entity.holding(DASH))
        end
    })

    movement.addTransition({
        from = "jumping",
        to = "air_dash",
        condition = function ()
            return entity.pressed(DASH) and entity.get(CAN_DASH)
        end
    })

    movement.addTransition({
        from = "jumping",
        to = "wall_jump",
        condition = function ()
            return movement.is(WALL_JUMP)
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
            return not entity.get(FALLING) and not entity.pressed(DASH) and not (entity.holding(LEFT) or entity.holding(RIGHT))
        end
    })

    movement.addTransition({
        from = "falling",
        to = "running",
        condition = function ()
            return not entity.get(FALLING) and not entity.pressed(DASH) and (entity.holding(LEFT) or entity.holding(RIGHT))
        end
    })

    movement.addTransition({
        from = "falling",
        to = "air_dash",
        condition = function ()
            return entity.pressed(DASH) and entity.get(CAN_DASH)
        end
    })

    movement.addTransition({
        from = "falling",
        to = "climbing",
        condition = function ()
            return not entity.pressed(JUMP) and movement.isSet("climbing") and entity.get(FALLING) and entity.getDeltaY() == 0 and not entity.pressed(DASH)
        end
    })

    movement.addTransition({
        from = "falling",
        to = "wall_jump",
        condition = function ()

            return entity.getFacingWall() ~= nil and entity.pressed(JUMP) and not entity.pressed(DASH)
        end
    })

    movement.addTransition({
        from = "climbing",
        to = "standing",
        condition = function ()
            return not entity.get(FALLING) and not entity.pressed(DASH) and not entity.pressed(JUMP)
        end
    })

    movement.addTransition({
        from = "climbing",
        to = "air_dash",
        condition = function ()
            return entity.pressed(DASH) and entity.get(CAN_DASH)
        end
    })

    movement.addTransition({
        from = "climbing",
        to = "wall_jump",
        condition = function ()
            return entity.pressed(JUMP)
        end
    })

    movement.addTransition({
        from = "climbing",
        to = "falling",
        condition = function ()
            local clinging    = entity.holding(entity.getFacing() == LEFT and RIGHT or LEFT)
            local pushing_off = entity.holding(entity.getFacing())

            -- TODO I would like to push megaman about half his senses distance away from the wall he was clinging
            -- when he "pushes off"
            return (not clinging and not entity.pressed(JUMP)) or (clinging and pushing_off) or entity.getFacingWall() == nil
        end
    })

    movement.addTransition({
        from = "wall_jump",
        to = "jumping",
        condition = function ()
            return entity.getFacingWall() ~= entity.getFacing() and entity.holding(JUMP)
        end
    })

    movement.addTransition({
        from = "wall_jump",
        to = "falling",
        condition = function ()
            return entity.getFacingWall() ~= entity.getFacing() and not entity.holding(JUMP)
        end
    })

    movement.addTransition({
        from = "any",
        to = "shocked",
        condition = function ()
            return entity.get(SHOCKED)
        end
    })

    movement.addTransition({
        from = "shocked",
        to = "standing",
        condition = function ()
            return not entity.get(SHOCKED)
        end
    })

    movement.start("standing")

    return movement
end

