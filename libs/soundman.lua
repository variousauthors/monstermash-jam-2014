local SoundMan = {}
SoundMan.__index = SoundMan

local path = string.match(debug.getinfo(1).short_src,"(.-)[^\\/]-%.?[^%.\\/]*$")

function SoundMan.new()
    local self = {}
    setmetatable(self, SoundMan)

    self.shortcuts = {}
    self.thread = love.thread.newThread(path..'/soundman_thread.lua')
    self.dChannel = love.thread.getChannel('sound_debug')
    self.tChannel = love.thread.getChannel('sound')
    self.thread:start()

    return self
end

function SoundMan:reInitialize()
    if self.thread and self.thread:isRunning() then
        self.tChannel:supply('kill')
    end
    self.thread = love.thread.newThread('libs/sound_thread.lua')
    self.thread:start()
end

function SoundMan:getDebugMessageCount()
    return self.dChannel:getCount()
end

function SoundMan:getDebugMessage()
    return self.dChannel:pop()
end

function SoundMan:sendMessage(msg)
    self.tChannel:push(msg)
end

--
-- playSound(source, tags, [volume, srcType])
--
function SoundMan:playSound(source, tags, ...)
    self:sendMessage({'playSound', source, tags, unpack({...})})
end

--
-- playSoundLooping(source, tags, [volume, srcType])
--
function SoundMan:playSoundLoop(source, tags, ...)
    self:sendMessage({'playSoundLoop', source, tags, unpack({...})})
end

--
-- playSoundRegionLoop(source, tags, [volume, srcType,] regionStart, regionEnd)
--   Sound plays until it reaches "regionEnd" then seeks to "regionStart"
--
function SoundMan:playSoundRegionLoop(source, tags, ...)
    self:sendMessage({'playSoundRegionLoop', source, tags, unpack({...})})
end

--
-- playSoundRegionLoop(source, tags, [volume, srcType,] regionStart)
--   Sound plays until end, then seeks to "regionStart
--
function SoundMan:playSoundPartialLoop(source, tags, ...)
    self:sendMessage({'playSoundPartialLoop', source, tags, unpack({...})})
end

--
--
--
function SoundMan:stop(...)
    local tags = {...}
    if #tags > 0 then tags = table.concat(tags, ';') else tags = nil end
    self:sendMessage({'stop', tags})
end

--
--
--
function SoundMan:pause(...)
    local tags = {...}
    if #tags > 0 then tags = table.concat(tags, ';') else tags = nil end
    self:sendMessage({'resume', tags})
end

--
--
--
function SoundMan:resume(...)
    local tags = {...}
    if #tags > 0 then tags = table.concat(tags, ';') else tags = nil end
    self:sendMessage({'resume', tags})
end

--
--
--
function SoundMan:add(name, command, source, tags, ...)
    tags = table.concat({name, ';', tags})
    self.shortcuts[name] = {command, source, tags, unpack({...})}
    self:sendMessage({'touchResource', source, tags, unpack({...})})
    --inspect(self.shortcuts[name])
    return self.shortcuts[name]
end

--
--
--
function SoundMan:run(name, tags)
    local msg = deepcopy(self.shortcuts[name])
    if msg and tags then msg[3] = table.concat({tags, ';', msg[3]}) end
    self:sendMessage(msg)
end

--

return SoundMan
