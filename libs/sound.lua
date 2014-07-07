local Sound = {}
Sound.__index = Sound

function Sound.new()
    local self = {}
    setmetatable(self, Sound)

    self.shortcuts = {}
    self.thread = love.thread.newThread('libs/sound_thread.lua')
    self.dChannel = love.thread.getChannel('sound_debug')
    self.tChannel = love.thread.getChannel('sound')
    self.thread:start()

    return self
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
function Sound:stop(...)
    local tags = {...}
    if #tags > 0 then tags = table.concat(tags, ';') else tags = nil end
    self:sendMessage({'stop', tags})
end

--
--
--
function Sound:pause(...)
    local tags = {...}
    if #tags > 0 then tags = table.concat(tags, ';') else tags = nil end
    self:sendMessage({'resume', tags})
end

--
--
--
function Sound:resume(...)
    local tags = {...}
    if #tags > 0 then tags = table.concat(tags, ';') else tags = nil end
    self:sendMessage({'resume', tags})
end

--
--
--
function Sound:add(name, command, source, tags, ...)
    tags = table.concat({name, ';', tags})
    self.shortcuts[name] = {command, source, tags, unpack({...})}
    self:sendMessage({'touchResource', source, tags, unpack({...})})
    --inspect(self.shortcuts[name])
    return self.shortcuts[name]
end

--
--
--
function Sound:run(name, tags)
    local msg = deepcopy(self.shortcuts[name])
    if msg and tags then msg[3] = table.concat({tags, ';', msg[3]}) end
    self:sendMessage(msg)
end

--

return Sound
