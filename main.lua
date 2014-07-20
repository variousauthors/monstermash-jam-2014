
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"
require "libs/linked_list"

love.graphics.setDefaultFilter('nearest', 'nearest', 0)

Viewport  = require("libs/viewport")
VHS = require("libs/inputman_recorder")

Input  = require("input")
Sound  = require("sound")
World  = require("world")
Player = require("player")
Boss   = require("boss")
HUD    = require("hud")

function love.focus(f) gameIsPaused = not f end

function love.load(args)
    love.graphics.setBackgroundColor(0, 0, 0)
    view = Viewport.new({
        width  = global.screen_width,
        height = global.screen_height,
        scale  = global.scale
    })

    world = World.new()
    Input = VHS.new(Input, world)

    game_state = require("game")(world)
    menu_state = require("menu")

    game_state.start()
end

local tic = 0
local play_rate = 1
local cbCount = {
    pressed = 0,
    released = 0,
}
local cbCountCounter = 0

function love.update(dt)
    tic = tic + 1

    if tic < play_rate then return end
    tic = 0

    cbCountCounter = cbCountCounter + dt
    if(cbCountCounter > 10) then
        print("Love2d input events:", stringspect(cbCount))
        cbCountCounter = 0
    end

    -- Process Input events in order
    Input:processEventQueue(function(event, states)
        inspect({ event, states })
        for i,state in ipairs(states) do
            if game_state[event] then game_state[event](state) end
        end
    end)

    game_state.update(dt)

    --Sound:printDebugQueue()
    --Input:printDebugQueue()
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
        Input:startRecording()
    elseif (key:match("[1-9]")) then
        if Input:isRecording() then
            Input:save(key)
        else
            Input:playback(key)
        end
    elseif (key == 'r') then
        if not Input:isRecording() and not Input:isPlayback() then
            game_state.set("reset")
        end
    elseif (key == '-') then
        play_rate = math.min(play_rate * 2, 16)
    elseif (key == '=') then
        play_rate = math.max(play_rate / 2, 1)
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
