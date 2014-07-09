
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"
DEBUG = true
require "libs/linked_list"
DEBUG = false

Viewport  = require("libs/viewport")
VHS = require("libs/inputman_recorder")

Input  = require("input")
Sound  = require("sound")
World  = require("world")
Player = require("player")
Boss   = require("boss")

function love.focus(f) gameIsPaused = not f end

function love.load()

    love.graphics.setBackgroundColor(0, 0, 0)
    view = Viewport.new({width = global.screen_width,
                             height = global.screen_height,
                             scale = global.scale})

    world = World.new()
    Input = VHS.new(Input, world)

    rock     = Player(32, 140, "p1")
    opera    = Player(110, 300, "p2")
    protoman = Player(370, 300, "p3")
    vile     = Player(560, 140, "p4")

    gj            = GameJolt("1", nil)

    world:register(rock)
    world:register(protoman)
    world:register(vile)
    world:register(opera)

    game_state = require("game")(world)
    menu_state = require("menu")

    game_state.start()
end

local cbCount = {
    pressed = 0,
    released = 0,
}
local cbCountCounter = 0

function love.update(dt)
    cbCountCounter = cbCountCounter + dt
    if(cbCountCounter > 10) then
        print("Love2d input events:", stringspect(cbCount))
        cbCountCounter = 0
    end

    -- Process Input events in order
    Input:processEventQueue(function(event, states)
        for i,state in ipairs(states) do
            if game_state[event] then game_state[event](state) end
        end
    end)

    game_state.update(dt)

    Sound:printDebugQueue()
    Input:printDebugQueue()
end

function love.keypressed(key, isrepeat)
    if (not love.window.hasFocus()) then return end
    cbCount['pressed'] = cbCount['pressed'] + 1

    if (key == 'f11') then
        view:setFullscreen()
        view:setupScreen()
    elseif (key == 'f10') then
        love.event.quit()
    elseif (key == 'q') then
        Input:toggleRecording()
    elseif (key == '1') then
        if not Input:isRecording() then
            Input:playback()
        end
    end
end

function love.keyreleased(key)
    if (not love.window.hasFocus()) then return end
    cbCount['released'] = cbCount['released'] + 1
end

function love.gamepadpressed(joystick, button)
    if (not love.window.hasFocus()) then return end
    cbCount['pressed'] = cbCount['pressed'] + 1
end

function love.gamepadreleased(joystick, button)
    if (not love.window.hasFocus()) then return end
    cbCount['released'] = cbCount['released'] + 1
end

function love.draw()
    view:pushScale()
    game_state.draw()
    view:popScale()
end

function love.resize(w, h)
    view:fixSize(w, h)
end

function love.threaderror(thread, errorstr)
    print("Thread error!\n"..errorstr)
end

function love.joystickadded (j)
    Input:updateJoysticks()
end

function love.joystickremoved (j)
    Input:updateJoysticks()
end
