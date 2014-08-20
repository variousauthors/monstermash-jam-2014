
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
Player = require("player/player")
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

function love.update(dt)
    game_state.update(dt)

    --Sound:printDebugQueue()
    --Input:printDebugQueue()
end

-- Receives keyboard codes and Input states
function love.keypressed(key, isrepeat)
    if (not love.window.hasFocus()) then return end

    if (key == 'f11') then
        view:setFullscreen()
        view:setupScreen()
    elseif (key == 'f10') then
        love.event.quit()
    elseif (key == 'q') then
        Input:startRecording()
    elseif (key:match("^[1-9]$")) then
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
    else
        -- Pass through any states or non-global keys.
        game_state.keypressed(key)
    end
end

-- Receives keyboard codes and Input states
function love.keyreleased(key)
    if (not love.window.hasFocus()) then return end
    game_state.keyreleased(key)
end

function love.gamepadpressed(joystick, button)
    if (not love.window.hasFocus()) then return end
end

function love.gamepadreleased(joystick, button)
    if (not love.window.hasFocus()) then return end
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

function love.processevents()
    -- Process events.
    love.event.pump()
    -- Process Input events into queue
    Input:processEventQueue(function(event, states)
        for i,state in ipairs(states) do
            love.event.push(event, state)
        end
    end)
    for e,a,b,c,d in love.event.poll() do
        if e == "quit" then
            if not love.quit or not love.quit() then
                love.audio.stop()
                return
            end
        end
        love.handlers[e](a,b,c,d)
    end
    return true
end

function love.drawscreen(debug)
    if love.window.isCreated() then
        love.graphics.clear()
        love.graphics.origin()
        if love.draw then love.draw() end

        -- Print debug information nicely if it was passed along
        if (type(debug) == "table") then
            local insert = table.insert
            local printtable = {}
            for k,v in pairs(debug) do
                insert(printtable, k .. ": ")
                insert(printtable, v)
                insert(printtable, "\n")
            end
            local r,g,b,a = love.graphics.getColor()
            love.graphics.setColor(0,0,0)
            love.graphics.print(table.concat(printtable), 1, 1)
            love.graphics.setColor(r,g,b,a)
            love.graphics.print(table.concat(printtable))
        end

        -- Present the graphics
        love.graphics.present()
    end
end

function love.run()
    love.math.setRandomSeed(os.time())
    love.event.pump()
    love.load(arg)
    love.timer.step()

    local t = 0
    local updateCount = 0
    local frameCount = 0
    local internalRate = 1/60
    local nextTime = 0
    local updateRate = 0
    local maxFrameskip = 4

    -- Main loop
    while true do
        -- Tick-count/running time
        love.timer.step()
        t = t + love.timer.getDelta()

        -- Update at constant speed. Game will slow if maxFrameskip exceeded
        updateRate = 0
        while(t >= nextTime and updateRate < maxFrameskip ) do
            -- Update on a fixed timestep
            if not love.processevents() then return end
            love.update(internalRate)
            nextTime = nextTime + (internalRate)
            updateCount = updateCount + 1
            updateRate = updateRate + 1

            -- Update tickcount
            love.timer.step()
            t = t + love.timer.getDelta()
        end

        -- Draw
        love.drawscreen({
            t = t,
            updateCount = updateCount,
            frameCount = frameCount,
            internalFPS = "1/" .. (1/internalRate),
            frameskip = updateRate .. ":" .. maxFrameskip
        })
        frameCount = frameCount + 1

        love.timer.sleep(0.001)
    end
end
