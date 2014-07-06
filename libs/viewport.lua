local class = require('vendor/middleclass/middleclass')

local Viewport = class('Viewport')

local roundDownToNearest = function(val, multiple)
    return multiple * (math.floor(val/multiple))
end

function Viewport:initialize(opts)
    opts = opts or {}
    setmetatable(opts,{__index={
        width  = 640,
        height = 360,
        scale  = 0,
        fs     = false
    }})
    self:setWidth(opts.width)
    self:setHeight(opts.height)
    self:setScale(opts.scale)
    self:setFullscreen(opts.fs)
    self:setupScreen()
end

function Viewport:setupScreen()
    self:setScale(self.scale)
    love.graphics.setDefaultFilter('nearest', 'nearest', 0)
    if(self:setFullscreen(self.fs)) then
        love.window.setMode(0, 0, {fullscreen = true, fullscreentype = "desktop"})
    else
        love.window.setMode(self.width * self.r_scale,
                            self.height * self.r_scale,
                            {resizable = true})
    end
    self.r_width  = self.width * self.r_scale
    self.r_height = self.height * self.r_scale
    self.draw_ox  = (love.graphics.getWidth() -  (self.r_width)) / 2
    self.draw_oy  = (love.graphics.getHeight() - (self.r_height)) / 2
end

function Viewport:setScale(scale)
    local scale = roundDownToNearest(scale, 0.5)
    self.scale = scale

    local screen_w, screen_h = love.window.getDesktopDimensions()
    if (not self.fs) then
        -- subtract some height so that windowed mode doesn't scale
        -- beyond titlebar + application bar height in windows
        screen_w = screen_w - 64
        screen_h = screen_h - 96
    end

    local max_scale = math.min(roundDownToNearest(screen_w / self.width, 0.5),
                               roundDownToNearest(screen_h / self.height, 0.5))

    if (self.fs or (scale or 0) <= 0 or (scale or 0) > max_scale) then
        self.r_scale = max_scale
    else
        self.r_scale = scale
    end

    return self.r_scale
end

function Viewport:fixSize(w, h)
    local screen_w, screen_h = love.window.getDesktopDimensions()
    if (not self.fs) then
        -- subtract some height so that windowed mode doesn't scale
        -- beyond titlebar + application bar height in windows
        screen_w = screen_w - 64
        screen_h = screen_h - 96
    end

    local cur_scale = math.max(roundDownToNearest(w / self.width, 0.5),
                               roundDownToNearest(h / self.height, 0.5))

    print(cur_scale)

    local max_scale = math.min(roundDownToNearest(screen_w / self.width, 0.5),
                               roundDownToNearest(screen_h / self.height, 0.5))

    if (cur_scale < 1) then
        self.scale = 1
    elseif(cur_scale > max_scale) then
        self.scale = max_scale
    else
        self.scale = cur_scale
    end

    self:setupScreen()
end

function Viewport:getWidth()
    return self.width
end

function Viewport:setWidth(width)
    local screen_w, screen_h = love.window.getDesktopDimensions()
    self.width = math.floor(math.min(width, screen_w))
    return self.width
end

function Viewport:getHeight()
    return self.height
end

function Viewport:setHeight(height)
    local screen_w, screen_h = love.window.getDesktopDimensions()
    self.height = math.floor(math.min(height, screen_h))
    return self.height
end

function Viewport:getParams()
    return {
        width    = self.width,
        height   = self.height,
        scale    = self.scale,
        fs       = self.fs,
        r_scale  = self.r_scale,
        r_width  = self.r_width,
        r_height = self.r_height,
        draw_ox  = self.draw_ox,
        draw_oy  = self.draw_oy
    }
end

function Viewport:setFullscreen(mode)
    if (mode == nil) then
        self.fs = not self.fs
    elseif (mode) then
        self.fs = true
    else
        self.fs = false
    end

    return self.fs
end

function Viewport:pushScale()
    love.graphics.push()
    love.graphics.translate(self.draw_ox, self.draw_oy)
    love.graphics.scale(self.r_scale, self.r_scale)
    love.graphics.setScissor(self.draw_ox, self.draw_oy, self.r_width, self.r_height)
end

function Viewport:popScale()
    love.graphics.scale(1)
    love.graphics.pop()
    love.graphics.setScissor()
end

return Viewport
