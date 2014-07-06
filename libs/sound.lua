local class = require('vendor/middleclass/middleclass')

local Sound = class("Sound")

function love.threaderror(thread, errorstr)
  print("Thread error!\n"..errorstr)
end

function Sound:initialize()
  self.thread = love.thread.newThread('libs/sound_thread.lua')
  self.dChannel = love.thread.getChannel('sound_debug')
  self.tChannel = love.thread.getChannel('sound')
  self.thread:start()
end

function Sound:getDebugMessageCount()
  return self.dChannel:getCount()
end

function Sound:getDebugMessage()
  return self.dChannel:pop()
end

function Sound:sendMessage(msg)
  return self.tChannel:push(msg)
end

--

return Sound
