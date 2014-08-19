local InputMan = require("libs/inputman")

-- this is for ZIGGY JOYSTICK
local joysticks = love.joystick.getJoysticks()

for i = 1, 4 do
    local joystick = joysticks[i]
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
end

-- This is global because it will be queried from lots of places.
local mapping = require('controls')['statemappings']

return InputMan.new(mapping)
