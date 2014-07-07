return function(world)
    local fsm = FSM()

    fsm.addState({
        name       = "start",
        --init       = game.init,
        draw       = function ()
            world:draw()
        end,

        update     = function (dt)
            world:update(dt)
        end,

        keypressed = function (key)
            if(key == "pause") then fsm.set('pause') end
            world:keypressed(key)
        end,

        keyreleased = function (key)
            world:keyreleased(key)
        end
    })

    fsm.addState({
        name = "pause",
        draw = function()
            world:draw()
            local w = View:getWidth()
            local h = View:getWidth()
            love.graphics.setColor(0, 0, 0, 128)
            love.graphics.rectangle("fill", 0, 0, w, h)
            love.graphics.setColor(255, 255, 255, 255)
        end,
        keypressed = function(key)
            print(key)
            if(key == "pause") then fsm.set('unpause') end
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
            return false
        end
    })

    fsm.addTransition({
        from      = "start",
        to        = "pause",
        condition = function ()
            return fsm.isSet('pause')
        end
    })

    fsm.addTransition({
        from      = "pause",
        to        = "start",
        condition = function ()
            return fsm.isSet('unpause')
        end
    })

    return fsm
end
