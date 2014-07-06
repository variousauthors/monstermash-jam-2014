local class = require('vendor/middleclass/middleclass')

local SoundObject = class("SoundObject")

SoundObjects = SoundObjects or {}

function SoundObject:initialize(source, tags, volume, srcType, callbacks)
    self.source = love.audio.newSource(source, srcType)
    self.source:setVolume(volume or 1)

    if (type(tags) == 'table') then
        self.tags = tags
    elseif(not tags) then
        self.tags = {}
    else
        self.tags = {tags}
    end

    self.callbacks = callbacks or {}

    table.insert(SoundObjects, self)
end

function SoundObject:hasTag(tag)
    for k,v in ipairs(self.tags) do
        if (tag == "all" or v == tag) then
            return true
        end
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
    self.callbacks["onStop"] = function() return false end
    self.callbacks["onTick"] = function(self, dt)
        local volume = self.source:getVolume()
        if (volume <= 0) then
            self.callbacks = {}
            self.source:stop()
        else
            self.source:setVolume(volume - (time / dt))
        end
    end
end

--

return SoundObject