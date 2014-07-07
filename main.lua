
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
    View = Viewport.new({width = global.screen_width,
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

    Sound:run("mainMusic")

    game_state.start()
end

function love.update(dt)
    game_state.update(dt)

    while Sound:getDebugMessageCount() > 0 do
        local msg = Sound:getDebugMessage()
        if msg then
            if(type(msg) == 'string') then print(msg) else
                print(stringspect(msg))
            end
        end
    end

end

function love.keypressed(key, isrepeat)
    if (key == 'f11') then
        View:setFullscreen()
        View:setupScreen()
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

-- function love.textinput(text)
--     game_state.textinput(text)
-- end

function love.draw()
    View:pushScale()
    game_state.draw()
    View:popScale()
end

function love.resize(w, h)
    View:fixSize(w, h)
end

function love.threaderror(thread, errorstr)
    print("Thread error!\n"..errorstr)
end
