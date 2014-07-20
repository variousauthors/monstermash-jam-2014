
return function(world)
    local fsm = FSM()

    fsm.addState({
        name       = "start",
        init       = function ()
            world:init()

            rock     = Player(32, 140, "p1", "rock")
            opera    = Player(110, 300, "p2", "opera")
            --protoman = Player(370, 300, "p3", "rock")
            --vile     = Player(560, 140, "p4", "opera")

            hud = HUD.new(rock, opera, protoman, vile)

            gj = GameJolt("1", nil)

            world:register(rock)
            world:register(opera)
            --world:register(protoman)
            --world:register(vile)

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
