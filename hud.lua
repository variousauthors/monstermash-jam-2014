local HUD = {}
HUD.__index = HUD

local img_healthbar_base = love.graphics.newImage('assets/ui/healthbar-base.png')
local img_healthbar_tic  = love.graphics.newImage('assets/ui/healthbar-tic.png')
local img_healthbar_tags = { }

local healthbar_w = img_healthbar_base:getWidth()
local healthbar_h = img_healthbar_base:getHeight()

function HUD.new(...) -- takes a list of up to 4 player objects
    local self = setmetatable({}, HUD)

    local xo, yo = 8, 8
    self._coords = {
        {view:lefttop(xo, yo, healthbar_w, healthbar_h)},
        {view:righttop(xo, yo, healthbar_w, healthbar_h)},
        {view:leftbottom(xo, yo, healthbar_w, healthbar_h)},
        {view:rightbottom(xo, yo, healthbar_w, healthbar_h)}
    }

    self._players = {}
    for i = 1,4 do self._players[i] = select(i, ...) end

    for i, v in ipairs(self._players) do
        local name = v.get('name')
        img_healthbar_tags[i] = love.graphics.newImage('assets/ui/healthbar-p_'..name..'.png')
    end

    return self
end

function HUD:update(dt)
    --No-op
end

function HUD:draw()
    local max = math.max
    for i, player in ipairs(self._players) do
        local hp = player.get("hp")
        local x, y = unpack(self._coords[i])
        love.graphics.draw(img_healthbar_base, x, y)
        love.graphics.draw(img_healthbar_tags[i], x, y)
        while hp > 0 do
            love.graphics.draw(img_healthbar_tic, x, y, 0, 1, 1, 0, (2 * hp - 2))
            hp = hp -1
        end
    end
end

--

return HUD

