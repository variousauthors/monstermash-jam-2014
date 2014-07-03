
require "libs/audio"
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"

Viewport  = require("libs/viewport")

-- This is global because it will be queried from lots of places.
Input = require("libs/input"):new({
    p1_left   = {"k_left", "j1_leftx-", "j1_dpleft"},
    p1_right  = {"k_right", "j1_leftx+", "j1_dpright"},
    p1_jump   = {"k_z", "j1_a"},
    p1_shoot  = {"k_x", "j1_x"},
    p1_dash   = {"k_lshift", "j1_y", "j1_triggerright+1"},
    p2_left   = {"j2_leftx-", "j2_dpleft"},
    p2_right  = {"j2_leftx+", "j2_dpright"},
    p2_jump   = {"j2_a"},
    p2_shoot  = {"j2_x"},
    p2_dash   = {"j2_y"}
})

World  = require("world")
Player = require("player")
Boss   = require("boss")


function love.focus(f) gameIsPaused = not f end

function love.load()
    love.graphics.setBackgroundColor(0, 0, 0)
    viewport = Viewport:new({width = 256, height = 224})

    world         = World:new()
    mega_man      = Player(32, 140, "p1_controls")
    proto_man     = Player(96, 140, "p2_controls")
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

    local i = Input:pressed(key)
    if i then
        print('keypressed', i)
        game_state.keypressed(i)
    end
end

function love.keyreleased(key)
    local i = Input:released(key)
    if i then
        print('keyreleased', i)
        game_state.keyreleased(i)
    end
end

function love.gamepadpressed(joystick, button)
    local i = Input:pressed(joystick, button)
    if i then
        print('gamepadpressed', i)
        game_state.keypressed(i)
    end

end

function love.gamepadreleased(joystick, button)
    local i = Input:released(joystick, button)
    if i then
        print('gamepadreleased', i)
        game_state.keyreleased(i)
    end
end

function love.gamepadaxis(joystick, axis, value)
    local i = Input:axis(joystick, axis, value)
    if i then
        print('gamepadaxis', i)
        game_state.keypressed(i)
    end
end

function love.textinput(text)
    game_state.textinput(text)
end

function love.draw()
    viewport:pushScale()
    game_state.draw()
    viewport:popScale()
end
