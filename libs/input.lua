local class = require('vendor/middleclass/middleclass')

local Input = class('Input')

local joysticks = love.joystick.getJoysticks()

function love.joystickadded (j)
    joysticks = love.joystick.getJoysticks()
end

function love.joystickremoved (j)
    joysticks = love.joystick.getJoysticks()
end

local default_deadzone = 0.2

function Input:initialize(mapping, deadzone, callbacks)
    self.deadzone = deadzone or default_deadzone
    self.mapping = mapping
end

function Input:getJoyNum(hid)
    for i, joystick in pairs(joysticks) do
        if joystick == hid then return i end
    end
end

function Input:mappingToKey(mapping)
    local a, b, c, d = string.match(mapping:lower(), "(%a+)(%d?)_(%a+)([%+%-%.0-9]*)")
    b = tonumber(b)
    if (joystick[b]) then b = joystick[b] else b = nil end
    if (d ~= '+' or d ~= '-') then d = tonumber(d) end
    return a, b, c, d
end

function Input:keyToMapping(...)
    local arguments = {...}
    local device, key, direction = "", "", ""

    if (#arguments == 1) then -- keypressed/released(key)
        device = "k"
        key = arguments[1]
    end

    if (#arguments > 1) then -- gamepadpressed/released(joystick, button)
        device = "j" .. self:getJoyNum(arguments[1])
        key = arguments[2]
    end

    if (#arguments == 3) then -- gamepadaxis(joystick, axis, value)
        if (arguments[3] > 0) then
            direction = '+'
        elseif (arguments[3] < 0) then
            direction = '-'
        end
    end

    return (device .. "_" .. key .. direction):lower()
end

function Input:mappingToState(mapping)
    if not self.mapping or not love.window.hasFocus() then
        return false
    end

    for state, keys in pairs(self.mapping) do
        for key, val in pairs(keys) do
            local ml, vl = mapping:lower(), val:lower()
            if (ml == vl) then return state end
        end
    end
end

function Input:pressed(...)
    local mapping = self:keyToMapping(...)
    local state = self:mappingToState(mapping)
    print(state)
    return state
end

function Input:released(...)
    local mapping = self:keyToMapping(...)
    local state = self:mappingToState(mapping)
    print(state)
    return state
end

function Input:axis(j, a, v)
    if(math.abs(v) < self.deadzone) then return end
    local mapping = self:keyToMapping(j, a, v)
    local state = self:mappingToState(mapping)
    print(mapping)
    print(state)
    return state
end

function Input:isState(state)
    if not self.mapping or not love.window.hasFocus() then
        return false
    end

    for k, v in pairs(self.mapping[state]) do
        local device, joy, key, dir = Input.static.parseMapping(v)
        if (not key) then
            return false
        elseif (device == 'k') then
            if love.keyboard.isDown(key) then return true end
        elseif (device == 'j' and joy) then
            if (dir) then
                --Axis
                local axis = joy:getGamepadAxis(key)
                if (dir == "+") then
                    if axis >= self.deadzone then return true end
                elseif (dir > 0) then
                    if axis >= dir then return true end
                elseif (dir == "-") then
                    if axis <= -self.deadzone then return true end
                elseif (dir < 0) then
                    if axis <= dir then return true end
                end
            else
                --Button
                if joy:isGamepadDown(key) then return true end
            end
        end
    end
    return false
end

return Input
