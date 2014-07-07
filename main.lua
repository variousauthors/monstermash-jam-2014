
require "libs/fsm"
require "libs/gamejolt"
require "libs/vector"
require "libs/utility"

Viewport  = require("libs/viewport")

-- this is for ZIGGY JOYSTICK
local joysticks = love.joystick.getJoysticks()
local joystick = joysticks[1]
if (joystick and not joystick:isGamepad()) then
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
end

-- This is global because it will be queried from lots of places.
Input = require("libs/input"):new({
    p1_left   = {"k_left", "j1_dpleft"},
    p1_right  = {"k_right", "j1_dpright"},
    p1_jump   = {"k_z", "j1_a"},
    p1_shoot  = {"k_x", "j1_x"},
    p1_dash   = {"k_lshift", "j1_rightshoulder"},
    p2_left   = {"j2_dpleft"},
    p2_right  = {"j2_dpright"},
    p2_jump   = {"j2_a"},
    p2_shoot  = {"j2_x"},
    p2_dash   = {"j2_rightshoulder"},
    p3_left   = {"j3_dpleft"},
    p3_right  = {"j3_dpright"},
    p3_jump   = {"j3_a"},
    p3_shoot  = {"j3_x"},
    p3_dash   = {"j3_rightshoulder"},
    p4_left   = {"j4_dpleft"},
    p4_right  = {"j4_dpright"},
    p4_jump   = {"j4_a"},
    p4_shoot  = {"j4_x"},
    p4_dash   = {"j4_rightshoulder"}
})
Sound = require("libs/sound").new()

World  = require("world")
Player = require("player")
Boss   = require("boss")


function love.focus(f) gameIsPaused = not f end

function love.load()

    love.graphics.setBackgroundColor(0, 0, 0)
    viewport = Viewport.new({width = global.screen_width,
                             height = global.screen_height,
                             scale = global.scale})

    world    = World.new()
    rock     = Player(32, 140, "p1_controls")
    opera    = Player(110, 300, "p2_controls")
    protoman = Player(370, 300, "p3_controls")
    vile     = Player(560, 140, "p4_controls")

    chill_penguin = Boss()
    gj            = GameJolt("1", nil)

    world:register(rock)
    world:register(protoman)
    world:register(vile)
    world:register(opera)
    -- world:register(chill_penguin)

    -- SFX
    Sound:add("pellet", "playSound", "assets/sfx/pellet.mp3", "sfx", 1, "static")
    Sound:add("blast", "playSound", "assets/sfx/blast.mp3", "sfx", 1, "static")
    Sound:add("mega_blast", "playSound", "assets/sfx/mega_blast.mp3", "sfx", 1, "static")
    Sound:add("charge", "playSoundRegionLoop", "assets/sfx/charge.mp3", "sfx", 1, "static", 3.114910, 4.628900)
    Sound:add("jump", "playSound", "assets/sfx/jump.mp3", "sfx", 1, "static")
    Sound:add("wall_jump", "playSound", "assets/sfx/jump.mp3", "sfx", 1, "static")
    Sound:add("dash", "playSound", "assets/sfx/dash.mp3", "sfx", 1, "static")
    Sound:add("damaged", "playSound", "assets/sfx/damaged.mp3", "sfx", 1, "static")
    Sound:add("destroyed", "playSound", "assets/sfx/destroyed.mp3", "sfx", 1, "static")

    -- Music
    Sound:add("mainMusic","playSoundRegionLoop", "assets/music/bossbattle.mp3", "music", 4.25490, 32.431358)

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
        viewport:setFullscreen()
        viewport:setupScreen()
    elseif (key == 'f10') then
        love.event.quit()
    elseif (key == 'p') then
        Sound:runShortcut("pellet")
    end

    local i = Input:pressed(key)
    if i then
        print('keypressed', i)
        game_state:keypressed(i)
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

-- function love.gamepadaxis(joystick, axis, value)
--     local i = Input:axis(joystick, axis, value)
--     if i then
--         print('gamepadaxis', i)
--         game_state.keypressed(i)
--     end
-- end

function love.textinput(text)
    game_state.textinput(text)
end

function love.draw()
    viewport:pushScale()
    game_state.draw()
    viewport:popScale()
end

function love.resize(w, h)
    viewport:fixSize(w, h)
end

function love.threaderror(thread, errorstr)
    print("Thread error!\n"..errorstr)
end
