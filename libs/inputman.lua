local InputMan = {}
InputMan.__index = InputMan

-- Private variables/methods

local joysticks = love.joystick.getJoysticks()
local default_deadzone = 0.25

-- Overwriting joystick callbacks

function love.joystickadded (j)
    joysticks = love.joystick.getJoysticks()
end

function love.joystickremoved (j)
    joysticks = love.joystick.getJoysticks()
end

-- Public class

function InputMan.new(map, deadzone)
    local self = {}
    setmetatable(self, InputMan)

    self.deadzone = deadzone or default_deadzone
    self:setStateMap(map)

    return self
end

function InputMan:setStateMap(map)
    if(type(map) == 'table') then
        self.stateMap = map
    else
        self.stateMap = {}
    end
    self:genFlatMap()
end

function InputMan:genFlatMap()
    local flatMap = {}
    for state, keys in pairs(self.stateMap) do
        for key, val in pairs(keys) do
            if (not flatMap[val]) then
                flatMap[val] = state
            else
                print(string.format("WARN: `%s` already bound to `%s`, can't bind to `%s`",
                                    val, flatMap[val], state))
            end
        end
    end
    self.flatMap = flatMap
end

function InputMan:getJoyNum(hid)
    for i, joystick in pairs(joysticks) do
        if (joystick == hid) then return i end
    end
end

function InputMan:mappingToKey(mapping)
    local a, b, c, d = string.match(mapping, "(%a+)(%d?)_(%a+)([%+%-%.0-9]*)")
    b = tonumber(b)
    if (b and joysticks[b]) then
        b = joysticks[b]
    else
        b = nil
    end
    if (d ~= '+' and d ~= '-') then
        d = tonumber(d)
    end
    return a, b, c, d
end

function InputMan:keyToMapping(...)
    local arguments = {...}
    local num_args = #arguments
    local device, key, direction = '', '', ''

    if (num_args == 1) then -- keypressed/released(key)
        device = "k"
        key = arguments[1]
    elseif (num_args > 1) then -- gamepadpressed/released(joystick, button)
        device = table.concat({'j', self:getJoyNum(arguments[1])})
        key = arguments[2]
    end

    if (num_args == 3) then -- gamepadaxis(joystick, axis, value)
        direction = tonumber(arguments[3])
        if (direction and direction > 0) then
            direction = table.concat({'+', direction})
        end
    end

    return table.concat{device, "_", key, direction or ''}
end

function InputMan:mappingToState(mapping)
    for keys, state in pairs(self.flatMap) do
        if (mapping == keys) then
            return state
        elseif(string.find(mapping, "^j.*[%+%-]")) then
            local mm, ms, ma = string.match(mapping, "^j(.*)([%+%-])([%.0-9]*)$")
            local km, ks, ka = string.match(keys, "^j(.*)([%+%-])([%.0-9]*)$")
            if(mm == km and ms == ks and ma >= ka) then
                return state
            end
        end
    end
end

function InputMan:keyEvent(...)
    if (not love.window.hasFocus()) then return end

    local mapping = self:keyToMapping(...)
    return self:mappingToState(mapping)
end

function InputMan:axisEvent(j, a, v)
    if (not love.window.hasFocus()) then return
    elseif(math.abs(v) < self.deadzone) then return end

    local mapping = self:keyToMapping(j, a, v)
    return self:mappingToState(mapping)
end

function InputMan:pressed(...)
    return self:keyEvent(...)
end

function InputMan:released(...)
    return self:keyEvent(...)
end

function InputMan:axis(...)
    return self:axisEvent(...)
end

function InputMan:isState(state)
    if not (self.stateMap[state] and love.window.hasFocus() ) then return false end

    local result = false

    for k, v in pairs(self.stateMap[state]) do
        local device, joy, key, dir = self:mappingToKey(v)

        if (device == 'k') then
            if love.keyboard.isDown(key) then result = true end
        elseif (device == 'j' and joy) then
            if (dir) then
                local axis = joy:getGamepadAxis(key)
                if (dir == "+") then
                    if (axis >= self.deadzone) then result = true end
                elseif (dir == "-") then
                    if (axis <= -self.deadzone) then result = true end
                elseif (dir > 0) then
                    if (axis >= dir) then result = true end
                elseif (dir < 0) then
                    if (axis <= dir) then result = true end
                end
            else
                if (joy:isGamepadDown(key)) then result = true end
            end
        end
    end

    return result
end

--

return InputMan
