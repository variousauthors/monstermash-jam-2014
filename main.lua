
require "libs/audio"
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"

World  = require("world")
Player = require("player")
Boss   = require("boss")

function love.focus(f) gameIsPaused = not f end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)

    world         = World()
    mega_man      = Player(100, 500)
    chill_penguin = Boss()
    gj            = GameJolt("1", nil)

    world.register(mega_man)
    world.register(chill_penguin)

    state_machine = FSM()

    state_machine.addState({
        name       = "start",
      --init       = game.init,
        draw       = function ()
            world.draw()
            mega_man.draw()
            chill_penguin.draw()
        end,
        update     = function (dt)
            world.update(dt)

        end,
        keypressed = function (key)
            mega_man.keypressed(key) -- queues up the mega_man's next move
            chill_penguin.keypressed(key)

        end
    })

    state_machine.addState({
        name       = "stop",
      --init       = game.init,
      --draw       = game.drawfunction,
      --update     = game.update,
      --keypressed = game.keypressed
    })

    -- start the game when the mega_man chooses a menu option
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

