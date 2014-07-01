
require "libs/audio"
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"

Viewport  = require("libs/viewport")

World  = require("world")
Player = require("player")
Boss   = require("boss")


function love.focus(f) gameIsPaused = not f end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
    viewport = Viewport:new({width = 256, height = 224})

    world         = World()
    mega_man      = Player(128, 200)
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

        end,
        keyreleased = function (key)
            mega_man.keyreleased(key) -- queues up the mega_man's next move
            chill_penguin.keyreleased(key)
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

    state_machine.start()
end

function love.update(dt)
    state_machine.update(dt)
end

function love.keypressed(key, isrepeat)
    if (key == 'f11') then
        viewport:setFullscreen()
        viewport:setupScreen()
    elseif (key == 'f10') then
        love.event.quit()
    end

    state_machine.keypressed(key, isrepeat)
end

function love.keyreleased(key)
    state_machine.keyreleased(key)
end

function love.textinput(text)
    state_machine.textinput(text)
end

function love.draw()
    viewport:pushScale()
    state_machine.draw()
    viewport:popScale()
end
