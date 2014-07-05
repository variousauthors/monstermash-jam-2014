
require "libs/audio"
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"

Viewport  = require("libs/viewport")

local joysticks = love.joystick.getJoysticks()
joystick = joysticks[1]

-- this is for ZIGGY JOYSTICK
love.joystick.setGamepadMapping( joystick:getGUID(), "dpup", "button", 1)
love.joystick.setGamepadMapping( joystick:getGUID(), "dpdown", "button", 2)
love.joystick.setGamepadMapping( joystick:getGUID(), "dpleft", "button", 3)
love.joystick.setGamepadMapping( joystick:getGUID(), "dpright", "button", 4)
love.joystick.setGamepadMapping( joystick:getGUID(), "a", "button", 5)
love.joystick.setGamepadMapping( joystick:getGUID(), "b", "button", 6)
love.joystick.setGamepadMapping( joystick:getGUID(), "x", "button", 7)
love.joystick.setGamepadMapping( joystick:getGUID(), "y", "button", 8)
love.joystick.setGamepadMapping( joystick:getGUID(), "leftshoulder", "button", 9)
love.joystick.setGamepadMapping( joystick:getGUID(), "rightshoulder", "button", 10)
love.joystick.setGamepadMapping( joystick:getGUID(), "back", "button", 11)
love.joystick.setGamepadMapping( joystick:getGUID(), "start", "button", 12)
love.joystick.setGamepadMapping( joystick:getGUID(), "guide", "button", 13)
love.joystick.setGamepadMapping( joystick:getGUID(), "leftstick", "button", 14)
love.joystick.setGamepadMapping( joystick:getGUID(), "rightstick", "button", 15)
love.joystick.setGamepadMapping( joystick:getGUID(), "leftx", "axis", 1)
love.joystick.setGamepadMapping( joystick:getGUID(), "triggerright", "axis", 5)
love.joystick.setGamepadMapping( joystick:getGUID(), "triggerleft", "axis", 6)

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
    viewport = Viewport:new({width = global.screen_width, height = global.screen_height})

    world         = World:new()
    megaman      = Player(32, 140, "p1_controls")
    protoman     = Player(96, 140, "p2_controls")
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
            megaman.keypressed(key) -- queues up the megaman's next move
            protoman.keypressed(key)

        end,
        keyreleased = function (key)
            megaman.keyreleased(key) -- queues up the megaman's next move
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

    -- start the game when the megaman chooses a menu option
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
        game_state.keypressed(i)
    end
end

function love.keyreleased(key)
    local i = Input:released(key)
    if i then
        game_state.keyreleased(i)
    end
end

function love.gamepadpressed(joystick, button)
    local i = Input:pressed(joystick, button)
    if i then
        game_state.keypressed(i)
    end

end

function love.gamepadreleased(joystick, button)
    local i = Input:released(joystick, button)
    if i then
        game_state.keyreleased(i)
    end
end

function love.gamepadaxis(joystick, axis, value)
    local i = Input:axis(joystick, axis, value)
    if i then
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
