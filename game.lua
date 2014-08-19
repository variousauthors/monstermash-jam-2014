
return function(world)
    local fsm = FSM()

    fsm.addState({
        name = "title_menu",
        init = function() end,
        update = function() end,
        draw = function() end,
        keypressed = function()
        end
    })

    fsm.addState({
        name = "new_game",
        init = function()
            world:init()

            BasicMovementModule  = require("player/movement")
            BasicArmorModule     = require("player/armor")
            BasicXBuster         = require("player/x_buster")

            AnimationModule = require("player/animation")


            players = {
                Player(32, 140, "p1", "rock"),
            --  Player(110, 300, "p2", "opera"),
            --  Player(370, 300, "p3", "proto"),
            --  Player(560, 140, "p4", "violet")
            }

            for _, v in ipairs(players) do
                world:register(v)
                v.init(BasicMovementModule, BasicArmorModule, BasicXBuster, AnimationModule)
            end

            hud = HUD.new(unpack(players))

            gj = GameJolt("1", nil)

            Sound:stop()
            Sound:run("mainMusic")
            fsm.set("ready")
        end
    })

    fsm.addState({
        name       = "play",
        init       = function ()
            Sound:resume()
        end,
        draw       = function ()
            world:draw()
            hud:draw()
        end,
        update     = function (dt)
            world:update(dt)
        end,
        keypressed = function (key)
            world:keypressed(key)
            if (key == 'pause') then fsm.set('pause') end
        end,
        keyreleased = function (key)
            world:keyreleased(key)
        end
    })

    fsm.addState({
        name = "pause",
        init = function()
            Sound:pause()
        end,
        update = function() end,
        draw = function()
            world:draw()
            hud:draw()
            local r,g,b,a = love.graphics.getColor()
            love.graphics.setColor(0, 0, 0, 128)
            love.graphics.rectangle("fill", 0, 0, view:getWidth(), view:getHeight())
            love.graphics.setColor(r, g, b, a)
        end,
        keypressed = function(key)
            if (key == 'pause') then fsm.set('unpause') end
        end,
        keyreleased = function() end
    })

    fsm.addState({
        name       = "stop",
        --init       = game.init,
        --draw       = game.drawfunction,
        --update     = game.update,
        --keypressed = game.keypressed
    })

    -- skip title menu for the moment
    fsm.addTransition({
        from      = "title_menu",
        to        = "new_game",
        condition = function ()
            return true
        end
    })

    -- start the game when the rock chooses a menu option
    fsm.addTransition({
        from      = "new_game",
        to        = "play",
        condition = function ()
            if fsm.isSet("ready") then
                fsm.unset("ready")
                return true
            end
        end
    })

    fsm.addTransition({
        from      = "play",
        to        = "pause",
        condition = function ()
            if fsm.isSet("pause") then
                fsm.unset("pause")
                return true
            end
        end
    })

    fsm.addTransition({
        from      = "pause",
        to        = "play",
        condition = function ()
            if fsm.isSet("unpause") then
                fsm.unset("unpause")
                return true
            end
        end
    })


    fsm.addTransition({
        from      = "any",
        to        = "new_game",
        condition = function ()
            if fsm.isSet("reset") then
                fsm.unset("reset")
                return true
            end
        end
    })

    return fsm
end
