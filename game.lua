
return function(world)
    local fsm = FSM()

    fsm.addState({
        name       = "start",
        init       = function ()
            world:init()

            players = {
                Player(32, 140, "p1", "rock"),
              --Player(110, 300, "p2", "opera"),
              --Player(370, 300, "p3", "proto"),
                --Player(560, 140, "p4", "vile")
            }

            for _, v in ipairs(players) do world:register(v) end

            hud = HUD.new(unpack(players))

            gj = GameJolt("1", nil)

            Sound:stop("music")
            Sound:run("mainMusic")
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
        end,
        keyreleased = function (key)
            world:keyreleased(key)
        end
      })

    fsm.addState({
        name       = "stop",
        --init       = game.init,
        --draw       = game.drawfunction,
        --update     = game.update,
        --keypressed = game.keypressed
    })

    -- start the game when the rock chooses a menu option
    fsm.addTransition({
        from      = "start",
        to        = "stop",
        condition = function ()
            return fsm.isSet("reset")
        end
    })

    fsm.addTransition({
        from      = "stop",
        to        = "start",
        condition = function ()
            return true
        end
    })

    return fsm
end
