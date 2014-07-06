
local i = require("vendor/inspect/inspect")
inspect = function (a, b)
    print(i.inspect(a, b))
end

stringspect = i.inspect

function math.round(val, decimal)
  local exp = decimal and 10^decimal or 1
  return math.ceil(val * exp - 0.5) / exp
end

rng = love.math.newRandomGenerator(os.time())

COLOR = {
    RED    = { 200, 55, 55 },
    YELLOW = { 200, 200, 55 },
    GREEN  = { 55, 200, 55 },
    CYAN   = { 55, 200, 200 },
    BLUE   = { 55, 55, 200 },
    PURPLE = { 200, 55, 200 },
    GREY   = { 200, 200, 200 },
    WHITE  = { 255, 255, 255 },
    BLACK  = { 55, 55, 55 }
}
