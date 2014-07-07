local SoundObject = {}
SoundObject.__index = SoundObject

SoundObjects = SoundObjects or {}
SoundResources = SoundResources or {}

function SoundObject.getResource(source, srcType)
    srcType = srcType or 'stream'
    local key = table.concat({source, '_', srcType})
    if SoundResources[key] then return SoundResources[key] end

    local ext = string.match(source, "%.([^.]+)$")
    if (ext) then
        if(ext ~= 'wav') then
            SoundResources[key] = love.sound.newDecoder(source)
            if(srcType == 'static') then
                SoundResources[key] = love.sound.newSoundData(SoundResources[key])
            end
        else
            if(srcType == 'stream') then
                SoundResources[key] = love.sound.newDecoder(source)
            elseif(srcType == 'static') then
                SoundResources[key] = love.sound.newSoundData(source)
            end
        end
        return SoundResources[key]
    end
end

function SoundObject.new(source, tags, volume, srcType, callbacks)
    local i = {}
    setmetatable(i, SoundObject)

    local resource = SoundObject.getResource(source, srcType)
    i.source = love.audio.newSource(resource, srcType)
    i.source:setVolume(volume or 1)

    i.tags = {}
    if tags then
        for token in string.gmatch(tags,"([^%,%;%s]+)") do
            table.insert(i.tags, token)
        end
    end

    i.callbacks = callbacks or {}

    table.insert(SoundObjects, i)

    return i
end

function SoundObject:hasTag(tags)
    if(type(tags) == "string") then tags = {tags} end
    local toFind = #tags
    for k, v in ipairs(self.tags) do
        if table.find(tags, v) then toFind = toFind - 1 end
        if (toFind == 0) then return true end
    end
end

function SoundObject:setVolume(volume)
    self.source:setVolume(volume)
end


function SoundObject:pause()
    self.source:pause()
end

function SoundObject:play()
    self.source:play()
end

function SoundObject:resume()
    self.source:resume()
end

function SoundObject:stop()
    self.callbacks = {}
    self.source:stop()
end

function SoundObject:finish()
    self.callbacks = {}
    self.source:setLooping(false)
end

function SoundObject:fadeOut(time)
    time = time or 5
    self.source:setLooping(false)
    self.callbacks["onStop"] = nil

    self.callbacks["_onTick"] = self.callbacks["onTick"] or (function() return end)
    self.callbacks["onTick"] = function(self, dt)
        self.callbacks["_onTick"](self, dt)
        local volume = self.source:getVolume()
        if (volume <= 0) then
            self.callbacks = {}
            self.source:stop()
        else
            self.source:setVolume(volume - (dt / time))
        end
    end
end

--

return SoundObject
