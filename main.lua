
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"

Viewport  = require("libs/viewport")

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

    world    = World.new()
    rock     = Player(32, 140, "p1")
    opera    = Player(110, 300, "p2")
    protoman = Player(370, 300, "p3")
    vile     = Player(560, 140, "p4")

    chill_penguin = Boss()
    gj            = GameJolt("1", nil)

    world:register(rock)
    world:register(protoman)
    world:register(vile)
    world:register(opera)
    -- world:register(chill_penguin)

    game_state = require("game")(world)
    menu_state = require("menu")

    game_state.start()
end

local cbCount = {
    keypressed = 0,
    keyreleased = 0,
    gamepadpressed = 0,
    gamepadreleased = 0,
}
local cbCountCounter = 0

function love.update(dt)
    cbCountCounter = cbCountCounter + dt
    if(cbCountCounter >= 5) then
        cbCountCounter = 0
    end

    while Input:getEventMessageCount() > 0 do
        local event = Input:getEventMessage()
        local cb = table.remove(event, 1)
        for i,v in ipairs(event) do
            if game_state[cb] then game_state[cb](v) end
        end
    end

    game_state.update(dt)

    while Sound:getDebugMessageCount() > 0 do
        local msg = Sound:getDebugMessage()
        if(type(msg) == 'string') then print(msg) else
            print(stringspect(msg))
        end
    end

    while Input:getDebugMessageCount() > 0 do
        local msg = Input:getDebugMessage()
        if(type(msg) == 'string') then print(msg) else
            print(stringspect(msg))
        end
    end
end



function love.keypressed(key, isrepeat)
    if (not love.window.hasFocus()) then return end

    cbCount['keypressed'] = cbCount['keypressed'] + 1

    if (key == 'f11') then
        view:setFullscreen()
        view:setupScreen()
    elseif (key == 'f10') then
        love.event.quit()
    end
end

function love.keyreleased(key)
    if (not love.window.hasFocus()) then return end

    cbCount['keyreleased'] = cbCount['keyreleased'] + 1
end

function love.gamepadpressed(joystick, button)
    if (not love.window.hasFocus()) then return end

    cbCount['gamepadpressed'] = cbCount['gamepadpressed'] + 1
end

function love.gamepadreleased(joystick, button)
    if (not love.window.hasFocus()) then return end

    cbCount['gamepadreleased'] = cbCount['gamepadreleased'] + 1
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
