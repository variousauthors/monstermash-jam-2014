
require "libs/audio"
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"

World  = require("world")
Player = require("player")

function love.focus(f) gameIsPaused = not f end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)

    world  = World()
    player = Player()
    gj     = GameJolt("1", nil)

    world.register(player)

    state_machine = FSM()

    state_machine.addState({
        name       = "start",
      --init       = game.init,
        draw       = function ()
            world.draw()
            player.draw()
        end,
        update     = function (dt)
            world.update(dt) -- tries to move the player
            player.update(dt)

        end,
        keypressed = function (key)
            player.keypressed(key) -- queues up the player's next move

        end
    })

    state_machine.addState({
        name       = "stop",
      --init       = game.init,
      --draw       = game.drawfunction,
      --update     = game.update,
      --keypressed = game.keypressed
    })

    -- start the game when the player chooses a menu option
    state_machine.addTransition({
        from      = "start",
        to        = "stop",
        condition = function ()
            return false
        end
    })

    love.update     = state_machine.update
    love.keypressed = state_machine.keypressed
    love.textinput  = state_machine.textinput
    love.draw       = state_machine.draw

    state_machine.start()
end

