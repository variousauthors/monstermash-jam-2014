local InputMan = {}
InputMan.__index = InputMan

if not json then require('vendor/lua4json/json4lua/json/json') end

local path = string.match(debug.getinfo(1).short_src,"(.-)[^\\/]-%.?[^%.\\/]*$")
local InputMapper = require(path..'/inputman_mapper')

function InputMan.new(mapping)
    local self = {}
    setmetatable(self, InputMan)

    self.thread = love.thread.newThread(path..'/inputman_thread.lua')
    self.eChannel = love.thread.getChannel('input_events')
    self.cChannel = love.thread.getChannel('input_commands')
    self.rChannel = love.thread.getChannel('input_responses')
    self.dChannel = love.thread.getChannel('input_debug')
    self.thread:start()

    self.localMapper = InputMapper.new(mapping)

    self:sendMessage({"setStateMap", json.encode(mapping)})

    return self
end

function InputMan:reInitialize()
    if self.thread and self.thread:isRunning() then
        self.tChannel:supply({'kill'})
    end
    self.thread = love.thread.newThread(path..'/input_thread.lua')
    self.thread:start()
end

function InputMan:updateJoysticks()
    self:sendMessage({'updateJoysticks'})
    self.localMapper:updateJoysticks()
end

function InputMan:sendMessage(msg)
    self.cChannel:push(msg)
end

function InputMan:getDebugMessageCount()
    return self.dChannel:getCount()
end

function InputMan:getDebugMessage()
    return self.dChannel:pop()
end

function InputMan:getEventMessageCount()
    return self.eChannel:getCount()
end

function InputMan:getEventMessage()
    return self.eChannel:pop()
end

function InputMan:isState(state)
    return self.localMapper:isState(state)
end

--

return InputMan
