local class = require('vendor/middleclass/middleclass')

local Sound = class("Sound")

function Sound:initialize()
    self.shortcuts = {}
    self.thread = love.thread.newThread('libs/sound_thread.lua')
    self.dChannel = love.thread.getChannel('sound_debug')
    self.tChannel = love.thread.getChannel('sound')
    self.thread:start()
end

function Sound:reInitialize()
    if self.thread and self.thread:isRunning() then
        self.tChannel:supply('kill')
    end
    self.thread = love.thread.newThread('libs/sound_thread.lua')
    self.thread:start()
end

function Sound:getDebugMessageCount()
    return self.dChannel:getCount()
end

function Sound:getDebugMessage()
    return self.dChannel:pop()
end

function Sound:sendMessage(msg)
    self.tChannel:push(msg)
end

--
-- playSound(source, tags, [volume, srcType])
--
function Sound:playSound(source, tags, ...)
    self:sendMessage({'playSound', source, tags, unpack({...})})
end

--
-- playSoundLooping(source, tags, [volume, srcType])
--
function Sound:playSoundLoop(source, tags, ...)
    self:sendMessage({'playSoundLoop', source, tags, unpack({...})})
end

--
-- playSoundRegionLoop(source, tags, [volume, srcType,] regionStart, regionEnd)
--   Sound plays until it reaches "regionEnd" then seeks to "regionStart"
--
function Sound:playSoundRegionLoop(source, tags, ...)
    self:sendMessage({'playSoundRegionLoop', source, tags, unpack({...})})
end

--
-- playSoundRegionLoop(source, tags, [volume, srcType,] regionStart)
--   Sound plays until end, then seeks to "regionStart
--
function Sound:playSoundPartialLoop(source, tags, ...)
    self:sendMessage({'playSoundPartialLoop', source, tags, unpack({...})})
end

--
--
--
function Sound:stop(tags)
   self:sendMessage({'stop', tags})
end

--
--
--
function Sound:pause(tags)
    self:sendMessage({'resume', tags})
end

--
--
--
function Sound:resume(tags)
    self:sendMessage({'resume', tags})
end

--
--
--
function Sound:addShortcut(name, command, source, tags, ...)
    tags = table.concat({name, ';', tags})
    self.shortcuts[name] = {command, source, tags, unpack({...})}
    inspect(self.shortcuts[name])
    return self.shortcuts[name]
end

--
--
--
function Sound:runShortcut(name, tags)
    local msg = deepcopy(self.shortcuts[name])
    if msg and tags then msg[3] = table.concat({tags, ';', msg[3]}) end
    self:sendMessage(msg)
end

--

return Sound
