require('love.timer')
require('love.joystick')
require('love.keyboard')

require('libs/utility')
if not json then require('vendor/lua4json/json4lua/json/json') end

local path = string.match(debug.getinfo(1).short_src,"(.-)[^\\/]-%.?[^%.\\/]*$")

local InputMapper = require(path..'/inputman_mapper').new()
local input_states = {}
local pressCount = 0
local releaseCount = 0

-- All the important numbers/counters

local _stop = false
local _epsilon = 0.0000001
local _throttle = 3000
local _time = love.timer.getTime()
local _threadStart = _time
local _dt = 0
local _loopStart = _time
local _threadTime = 0
local _loopCount = 0
local _loopRate = _epsilon
local _debugAcc = 0

local eChannel = love.thread.getChannel("input_events")
local cChannel = love.thread.getChannel("input_commands")
local dChannel = love.thread.getChannel("input_debug")
local callbacks = {}

-- Callbacks

callbacks['setStateMap'] = function(mapstring)
    local map = json.decode(mapstring)
    InputMapper:setStateMap(map)
end

callbacks['updateJoysticks'] = function()
    InputMapper:updateJoysticks()
end

local inputTick = function(dt)
    local active = InputMapper:getStates()
    local kactive = {}
    local pressed = {'keypressed'}
    local released = {'keyreleased'}

    for k, state in pairs(active) do
        kactive[state] = true
        if(not input_states[state]) then
            table.insert(pressed, state)
        end
    end

    for state, status in pairs(input_states) do
        if (not kactive[state]) then
            table.insert(released, state)
            input_states[state] = nil
        end
    end

    if(#pressed > 1) then
        pressCount = pressCount + #pressed - 1
        eChannel:push(pressed)
    end

    if(#released > 1) then
        releaseCount = releaseCount + #released - 1
        eChannel:push(released)
    end

    input_states = kactive
end

-- Main Thread Loop

while not _stop do
    _time = love.timer.getTime()
    _dt = _time - _loopStart
    _threadTime = _time - _threadStart
    _loopStart = _time
    _loopCount = _loopCount + 1
    _loopRate = _loopCount / _threadTime

    inputTick(_dt)

    local msg = cChannel:pop()

    if type(msg) == 'table' then
        local callback = table.remove(msg, 1)
        dChannel:push({"INPUT: ", callback, unpack(msg)})
        if(callbacks[callback]) then
            local result = callbacks[callback](unpack(msg))
        else
            dChannel:push({"INPUT ERROR: ", callback, "doesn't exist"})
        end
    end

    -- Debug / EndLoop
    _debugAcc = _debugAcc + _dt
    if(_debugAcc > 5) then
        dChannel:push({"INPUT-DEBUG: ",_loopCount, _threadTime, _loopRate, pressCount, releaseCount})
        _debugAcc = 0
    end

    --Throttle
    if (_loopRate > _throttle) then love.timer.sleep(0.001) end
end
