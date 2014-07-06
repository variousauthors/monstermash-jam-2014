require('love.timer')
require('love.filesystem')
require('love.audio')
require('love.sound')

local i = require("vendor/inspect/inspect")

local SoundObject = require('libs/sound_object')
SoundObjects = SoundObjects or {}

local _stop = false
local _epsilon = 0.0000001
local _throttle = 100000
local _time = love.timer.getTime()
local _threadStart = _time
local _dt = 0
local _loopStart = _time
local _threadTime = 0
local _loopCount = 0
local _loopRate = _epsilon
local _debugAcc = 0

local tChannel = love.thread.getChannel("sound")
local dChannel = love.thread.getChannel("sound_debug")
local callbacks = {}

--Functions
local soundTick = function(dt)
    for k, v in ipairs(SoundObjects) do
        if v.source:isStopped() then
            if v.callbacks['onStop'] and v.callbacks['onStop'](v, dt) then
                -- no-op
            else
                table.remove(SoundObjects, k)
            end
        elseif v.callbacks['onTick'] then
            v.callbacks['onTick'](v, dt)
        end
    end
end

callbacks['playSound'] = function(...)
    local snd = SoundObject:new(...)
    snd:play()
end

callbacks['playSoundLoop'] = function(...)
    local snd = SoundObject:new(...)
    snd.source:setLooping(true)
    snd:play()
end

callbacks['playSoundRegionLoop'] = function(...)
    local args = {...}
    local regionEnd = table.remove(args)
    local regionStart = table.remove(args)
    local source, tags, volume, srcType = unpack(args)

    local cb = function(self, dt)
        if(self.source:tell("seconds") >= regionEnd) then
            self.source:seek(regionStart, "seconds")
            dChannel:push("DEBUG: Restarted Loop", regionStart)
        end
    end

    local snd = SoundObject:new(source, tags, volume, srcType, {onTick = cb})
    snd:play()
end

callbacks['playSoundPartialLoop'] = function(...)
    local args = {...}
    local regionStart = table.remove(args)
    local source, tags, volume, srcType = unpack(args)

    local cb = function(self, dt)
        self.source:play()
        self.source:seek(regionStart, "seconds")
        return true
    end

    local snd = SoundObject:new(source, tags, volume, srcType, {onStop = cb})
    snd:play()
end

callbacks['stopTag'] = function(tag)
    for i, sound in ipairs(SoundObjects) do
        if sound:hasTag(tag) then sound:stop() end
    end
end

callbacks['pauseTag'] = function(tag)
    for i, sound in ipairs(SoundObjects) do
        if sound:hasTag(tag) then sound:pause() end
    end
end

callbacks['resumeTag'] = function(tag)
    for i, sound in ipairs(SoundObjects) do
        if sound:hasTag(tag) then sound:resume() end
    end
end

-- Main Thread Loop

while not _stop do
    _time = love.timer.getTime()
    _dt = _time - _loopStart
    _threadTime = _time - _threadStart
    _loopStart = _time
    _loopCount = _loopCount + 1
    _loopRate = _loopCount / _threadTime

    soundTick(_dt)

    local msg = tChannel:pop()
    if type(msg) == 'table' then
        local callback = table.remove(msg, 1)
        dChannel:push({"SOUND: ", callback, unpack(msg)})

        if(callbacks[callback]) then
            local result = callbacks[callback](unpack(msg))
        else
            dChannel:push({"ERROR: ", callback, "doesn't exist"})
        end
    end

    -- Debug / EndLoop
    _debugAcc = _debugAcc + _dt
    if(_debugAcc > 2) then
        dChannel:push({"DEBUG: ",_loopCount, _threadTime, _loopRate})
        _debugAcc = 0
    end

    --Throttle
    if (_loopRate > _throttle) then love.timer.sleep(0.001) end
end
