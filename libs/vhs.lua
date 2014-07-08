local VHS = {}
VHS.__index = VHS

if not stringspect then stringspect = require('vendor/inspect/inspect') end
if not json then require('vendor/lua4json/json4lua/json/json') end

local path = string.match(debug.getinfo(1).short_src,"(.-)[^\\/]-%.?[^%.\\/]*$")

function VHS.new(inputMan)
    local self = {}
    setmetatable(self, VHS)

    self.inputMan = inputMan
    self.recording = { {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, { { "keypressed", "p1_left" } }, {}, {}, {}, {}, {}, {}, { { "keypressed", "p1_right" }, { "keyreleased", "p1_left" } }, {}, {}, {}, {}, {}, {}, {}, {}, {}, { { "keyreleased", "p1_right" }, { "keypressed", "p1_left" } }, {}, {}, {}, {}, {}, {}, {}, {}, { { "keyreleased", "p1_left" } }, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {} }

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

local sneak = function (cb)
end

function VHS:processEventQueue(cb)
    if self.playback then
        -- Process Input events in order
        
        local update = table.remove(self.recording, 1)

        while update and #update > 0 do
            local msg = table.remove(update, 1)
            local event = table.remove(msg, 1)
            cb(event, msg)
        end
    else
        -- play the game normally, but remember the events
        self.inputMan:processEventQueue(function (event, states)
            table.insert(self.recording, { event, unpack(states ) })
            cb(event, states)
        end)
    end
end

function VHS:printDebugQueue()
    self.inputMan:printDebugQueue()
end

function VHS:isState(state)
    return self.inputMan:isState(state)
end

function VHS:playback()
    self.playback = true
end

return VHS
