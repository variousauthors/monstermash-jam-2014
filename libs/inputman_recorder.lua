local VHS = {}
VHS.__index = VHS

if not stringspect then stringspect = require('vendor/inspect/inspect') end
if not json then require('vendor/lua4json/json4lua/json/json') end

local path = string.match(debug.getinfo(1).short_src,"(.-)[^\\/]-%.?[^%.\\/]*$")

function VHS.new(inputMan)
    local self = {}
    setmetatable(self, VHS)

    self.inputMan = inputMan
    self.recording = PaddedQueue({})

    self._playback = false
    self._record   = false

    return self
end

function VHS:sendCommand(msg)
    self.inputMan:sendCommand(msg)
end

function VHS:setStateMap(mapping)
    self.inputMan:setStateMap(mapping)
end

function VHS:updateJoysticks()
    self.inputMan:updateJoysticks()
end

function VHS:reInitialize()
    self.inputMan:reInitialize()
end

function VHS:processEventQueue(cb)
    if self._playback and self.recording.isEmpty() then self._playback = false end

    local update

    if self._playback then
        -- Process Input events in order
        update = self.recording.dequeue()

        while update and #update > 0 do
            local msg = table.remove(update, 1)
            local event = table.remove(msg, 1)
            cb(event, msg)
        end
    else
        -- play the game normally, but remember the events
        self.inputMan:processEventQueue(function (event, states)
            if update == nil then update = {} end

            table.insert(update, { event, unpack(states) })

            cb(event, states)
        end)

        if self._record then self.recording.enqueue(update) end
    end
end

function VHS:printDebugQueue()
    self.inputMan:printDebugQueue()
end

function VHS:isState(state)
    return self.inputMan:isState(state)
end

function VHS:playback()
    self._record   = false
    self._playback = true
end

function VHS:record()
    self._playback = false
    self._record   = true
end

return VHS
