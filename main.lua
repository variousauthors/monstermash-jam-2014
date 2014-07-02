
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
    viewport = Viewport:new({width = global.screen_width, height = global.screen_height})

    world         = World:new()
    megaman      = Player(32, 140)
    protoman     = Player(96, 140)
    chill_penguin = Boss()
    gj            = GameJolt("1", nil)

    world:register(megaman)
    world:register(protoman)
    -- world:register(chill_penguin)

    game_state = FSM()

    game_state.addState({
        name       = "start",
      --init       = game.init,
        draw       = function ()
            world:draw()
        end,
        update     = function (dt)
            world:update(dt)
        end,
        keypressed = function (key)
            megaman.keypressed(key)
            protoman.keypressed(key)
        end,
        keyreleased = function (key)
            megaman.keyreleased(key)
            protoman.keyreleased(key)
        end
    })

    game_state.addState({
        name       = "stop",
      --init       = game.init,
      --draw       = game.drawfunction,
      --update     = game.update,
      --keypressed = game.keypressed
    })

    -- start the game when the mega_man chooses a menu option
    game_state.addTransition({
        from      = "start",
        to        = "stop",
        condition = function ()
            return false
        end
    })

    game_state.start()
end

function love.update(dt)
    game_state.update(dt)
end

function love.keypressed(key, isrepeat)
    if (key == 'f11') then
        viewport:setFullscreen()
        viewport:setupScreen()
    elseif (key == 'f10') then
        love.event.quit()
    end

    game_state.keypressed(key, isrepeat)
end

function love.keyreleased(key)
    game_state.keyreleased(key)
end

function love.textinput(text)
    game_state.textinput(text)
end

function love.draw()
    viewport:pushScale()
    game_state.draw()
    viewport:popScale()
end
