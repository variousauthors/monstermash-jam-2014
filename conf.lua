-- globals having to do with the tile library
global           = {}
global.tile_size = 16
global.scale     = 0
global.screen_width = 640
global.screen_height = 360

-- for now the high and low obstacles don't do anything, since
-- obstacles are visualized by the background/foreground
global.z_orders = {
    background    = 0, -- the background image
    low_obstacle  = 1, -- things bullets don't collide with
    bullets       = 2, -- ... bullets
    high_obstacle = 3, -- things bullets do collide with
    sprites       = 5, -- MEGAMAAAAAAN
    decorations   = 4, -- dust and sparks
    overlays      = 6, -- charge up etc...
}

function DEC_HEX(IN)
    local B,K,OUT,I,D=16,"0123456789abcdef","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end

sides = { 1005366685, 1351747387, 3316243027, 930149632 }
floor_height = 27754

global.side_length   = ""
global.floor_height  = "" .. floor_height

for i, v in ipairs(sides) do
    global.side_length = global.side_length .. DEC_HEX(v)
end

function love.conf(t)
    t.window.title = "The Dead"
end
