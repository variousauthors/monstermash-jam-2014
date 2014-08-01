
local SmokeTrail = require("decorations/smoke_trail")
local DashSparks = require("decorations/dash_sparks")

local smoke_dimension = SmokeTrail.WIDTH
local sparks_width    = DashSparks.WIDTH
local sparks_height   = DashSparks.HEIGHT

-- TODO assert that entity has the right interface
-- TODO better would be to pass in an object that only
-- exposes those methods: then we can do "if and only if"
-- entity must implement
-- set/get
-- pressed/holding
-- getFacing/setFacing
-- id

-- TODO all the string keys should be constants maybe
-- even in an object called "registers"

-- TODO get facing and get near_a_wall
-- are examples of non-boolean registers
-- they should be replaced with methods getFacing and senseWall
-- or something

return function (entity, controls, verbose)
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)
    local movement                       = FSM(false, "move", entity.get("name"))
    local dash_duration                  = 30
    local damaged_duration               = 30
    local smoke_interval = 4

    movement.addState({
        name = "standing",
        init = function ()
            entity.set("dash_jump", false)
            entity.set("shocked", false)
            entity.set("near_a_wall", nil)
            entity.set("can_dash", true)
            entity.set("air_dash", false)
        end
    })

    movement.addState({
        name = "destroyed",
        init = function()
            local id = entity.get("id")
            Sound:stop(id)
            Sound:run("destroyed", id)
        end
    })

    movement.addState({
        name = "running",
        init = function ()
            entity.set("dash_jump", false)
            entity.set("can_dash", true)
            entity.set("air_dash", false)
        end,
        -- TODO this is the kind of function I'd ilke
        -- to set in the player, and use the closure
        -- property
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
        init = function()
            entity.set("can_dash", false)
            local id = entity.get('id')
            Sound:run('dash', id)

        end,
        update = function ()
            if entity.holding(DASH) then
                entity.resolveDash()
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
            entity.set("can_dash", false)
            local id = entity.get('id')
            Sound:run('wall_jump', id)
            entity.set("dash_jump", true)
        end
    })

    movement.addState({
        name = "air_dash",
        init = function ()
            entity.set("can_dash", false)
            local id = entity.get('id')
            Sound:run('dash', id)
            entity.set("air_dash", true)
        end
    })

    movement.addState({
        name = "jumping",
        init = function ()
            local id = entity.get('id')

            -- if a jump starts near a wall, kick off
            entity.set("wall_jump", false)
            Sound:run('jump', id)

            -- if we are continuing from a wall jump there
            -- is no need to reset this
            -- TODO this is an example of a register with a non
            -- boolean value. I'd like to remove these
            -- maybe replace with `get("vertical_movement")`
            if entity.get("vs") == 0 then
                entity.startJump()
            end
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
        name = "wall_jump",
        init = function ()
            local id = entity.get('id')
            entity.set("wall_jump", true)
            entity.setFacing(entity.get("near_a_wall"))
            Sound:run('wall_jump', id)

            entity.set(FALLING, false)

            entity.startJump() -- TODO this has got to go... but how!?
        end,
        update = function ()
            -- wall jump can't be interrupted or air controlled
            entity.resolveJump()
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
            entity.set("can_dash", true)
        end,
        update = function ()
            if entity.holding(LEFT) then
                entity.resolveLeft()
            end

            if entity.holding(RIGHT) then
                entity.resolveRight()
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

    movement.addState({
        name = "damaged",
        init = function ()
            local id = entity.get('id')
            Sound:stop(id)
            Sound:run('damaged', id)
            entity.set("hp", math.max(entity.get("hp") - entity.get("damage_queue")))
            entity.set("damage_queue", 0)
            entity.set("invulnerable", 1)
            entity.set("dash_jump", false)
            entity.set("shocked", true)
        end,
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
            return entity.get("vs") > 0 and not (entity.holding(LEFT) or entity.holding(RIGHT))
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
            return entity.pressed(DASH) and entity.get("can_dash")
        end
    })

    movement.addTransition({
        from = "running",
        to = "standing",
        condition = function ()
            local running    = (entity.holding(LEFT) or entity.holding(RIGHT))
            local turning    = (entity.pressed(RIGHT) or entity.pressed(LEFT))

            return not entity.pressed(DASH) and (not running or press_both) and not turning and entity.get("vs") == 0
        end
    })

    movement.addTransition({
        from = "running",
        to = "jumping",
        condition = function ()

            return entity.pressed(JUMP) and entity.get("vs") == 0
        end
    })

    movement.addTransition({
        from = "running",
        to = "dashing",
        condition = function ()

            return entity.pressed(DASH) and entity.get("can_dash")
        end
    })

    movement.addTransition({
        from = "running",
        to = "falling",
        condition = function ()
            return entity.get("vs") > 0 and not entity.pressed(DASH)
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
            return entity.pressed(JUMP) and not entity.get("air_dash")
        end
    })

    movement.addTransition({
        from = "jumping",
        to = "falling",
        condition = function ()
            return entity.get("vs") == 0 or not entity.holding(JUMP) and not entity.holding(DASH)
        end
    })

    movement.addTransition({
        from = "jumping",
        to = "air_dash",
        condition = function ()
            return entity.pressed(DASH) and entity.get("can_dash")
        end
    })

    -- TODO this might not be necessary because megaman always goes to
    -- falling before walljump
    movement.addTransition({
        from = "jumping",
        to = "wall_jump",
        condition = function ()
            return movement.is("wall_jump")
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
            return entity.pressed(DASH) and entity.get("can_dash")
        end
    })

    movement.addTransition({
        from = "falling",
        to = "climbing",
        condition = function ()
            return not entity.pressed(JUMP) and movement.isSet("climbing") and entity.get(FALLING) and entity.get("vs") == 0 and not entity.pressed(DASH)
        end
    })

    movement.addTransition({
        from = "falling",
        to = "wall_jump",
        condition = function ()

            return entity.get("near_a_wall") ~= nil and entity.pressed(JUMP) and not entity.pressed(DASH)
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
            return entity.pressed(DASH) and entity.get("can_dash")
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
            return (not clinging and not entity.pressed(JUMP)) or (clinging and pushing_off) or entity.get("near_a_wall") == nil
        end
    })

    movement.addTransition({
        from = "wall_jump",
        to = "jumping",
        condition = function ()
            return entity.get("near_a_wall") ~= entity.getFacing() and entity.holding(JUMP)
        end
    })

    movement.addTransition({
        from = "wall_jump",
        to = "falling",
        condition = function ()
            return entity.get("near_a_wall") ~= entity.getFacing() and not entity.holding(JUMP)
        end
    })

    movement.addTransition({
        from = "any",
        to = "damaged",
        condition = function ()
            return entity.get("hp") > 0 and entity.get("damage_queue") and entity.get("damage_queue") > 0
        end
    })

    movement.addTransition({
        from = "any",
        to = "destroyed",
        condition = function ()
            -- TODO this kind of check (for entity death_line stuff) should be done in the player update and flagged
            -- HP also
            return not movement.is('destroyed') and (entity.get("hp") < 1 or entity.getY() > entity.get("death_line"))
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

