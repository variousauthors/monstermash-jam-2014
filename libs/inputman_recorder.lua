local VHS = {}
VHS.__index = VHS

if not stringspect then stringspect = require('vendor/inspect/inspect') end
if not json then require('vendor/lua4json/json4lua/json/json') end

local path = string.match(debug.getinfo(1).short_src,"(.-)[^\\/]-%.?[^%.\\/]*$")

function VHS.new(inputMan)
    local self = {}
    setmetatable(self, VHS)

    self.inputMan = inputMan
    self.recording = { 24, { { "keypressed", "p1_right" } }, 14, { { "keypressed", "p1_dash" } }, 4, { { "keypressed", "p1_jump" } }, 21, { { "keyreleased", "p1_jump", "p1_dash" } }, 11, { { "keypressed", "p1_shoot" } }, 3, { { "keyreleased", "p1_shoot" } }, 4, { { "keypressed", "p1_shoot" } }, 1, { { "keyreleased", "p1_shoot" } }, 15, { { "keypressed", "p1_shoot" } }, 4, { { "keyreleased", "p1_shoot" } }, 24, { { "keyreleased", "p1_right" } }, 3, { { "keypressed", "p1_left" } }, 5, { { "keypressed", "p1_jump" } }, 1, { { "keyreleased", "p1_left" } }, 1, { { "keyreleased", "p1_jump" } }, 10, { { "keypressed", "p1_shoot" } }, 9, { { "keyreleased", "p1_shoot" } }, 4, { { "keypressed", "p1_shoot" } }, 98, { { "keyreleased", "p1_shoot" } }, 22, { { "keypressed", "p1_shoot" } }, 3, { { "keyreleased", "p1_shoot" } }, 2, { { "keypressed", "p1_shoot" } }, 5, { { "keyreleased", "p1_shoot" } }, 86 }

    self._playback = false

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
    local update

    if self._playback then
        -- Process Input events in order
        update = self.recording[1]
        
        if type(update) == "number" then
            self.recording[1] = update - 1

            if self.recording[1] == 0 then
                table.remove(self.recording, 1)
            end
        else
            update = table.remove(self.recording, 1)

            while update and #update > 0 do
                local msg = table.remove(update, 1)
                local event = table.remove(msg, 1)
                cb(event, msg)
            end
        end
    else
        update = {}

        -- play the game normally, but remember the events
        self.inputMan:processEventQueue(function (event, states)
            table.insert(update, { event, unpack(states) })

            cb(event, states)
        end)

        if #update > 0 then
            table.insert(self.recording, update)
        else
            local last = self.recording[#(self.recording)]

            if type(last) == "number" then
                self.recording[#(self.recording)] = last + 1
            else
                table.insert(self.recording, 1)
            end
        end
    end
end

function VHS:printDebugQueue()
    self.inputMan:printDebugQueue()
end

function VHS:isState(state)
    return self.inputMan:isState(state)
end

function VHS:playback()
    self._playback = true
end

return VHS
