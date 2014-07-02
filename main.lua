
require "libs/audio"
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"

Viewport  = require("libs/viewport")
Input    = require("libs/input")

World  = require("world")
Player = require("player")
Boss   = require("boss")


function love.focus(f) gameIsPaused = not f end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
    viewport = Viewport:new({width = 256, height = 224})
    input = Input:new({
        P1_left   = {"K_left", "J1_leftx-", "J1_dpleft"},
        P1_right  = {"K_right", "J1_leftx+", "J1_dpright"},
        P1_jump   = {"K_z", "J1_a"},
        P1_shoot  = {"K_x", "J1_x"},
        P1_dash   = {"K_lshift", "J1_y"},

        P2_left   = {"J2_leftx-", "J2_dpleft"},
        P2_right  = {"J2_leftx+", "J2_dpright"},
        P2_jump   = {"J2_a"},
        P2_shoot  = {"J2_x"},
        P2_dash   = {"J2_y"}
    })

    world         = World:new()
    mega_man      = Player(32, 140)
    proto_man     = Player(96, 140)
    chill_penguin = Boss()
    gj            = GameJolt("1", nil)

    world:register(mega_man)
    world:register(proto_man)
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
            mega_man.keypressed(key) -- queues up the mega_man's next move
            proto_man.keypressed(key)

        end,
        keyreleased = function (key)
            mega_man.keyreleased(key) -- queues up the mega_man's next move
            proto_man.keyreleased(key)
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

    input:pressed(key)
    game_state.keypressed(key, isrepeat)
end

function love.keyreleased(key)
    input:released(key)
    game_state.keyreleased(key)
end

function love.gamepadpressed(joystick, button)
    input:pressed(joystick, button)
end

function love.gamepadreleased(joystick, button)
    input:released(joystick, button)
end

function love.gamepadaxis(joystick, axis, value)
    input:axis(joystick, axis, value)
end

function love.textinput(text)
    game_state.textinput(text)
end

function love.draw()
    viewport:pushScale()
    game_state.draw()
    viewport:popScale()
end
