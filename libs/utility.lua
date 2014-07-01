
local i = require("vendor/inspect/inspect")
inspect = function (a, b)
    print(i.inspect(a, b))
end

function math.round(val, decimal)
  local exp = decimal and 10^decimal or 1
  return math.ceil(val * exp - 0.5) / exp
end

COLOR = {
    RED    = { 200, 55, 55 },
    GREEEN = { 55, 200, 55 },
    BLUE   = { 55, 55, 200 },
    WHITE  = { 200, 200, 200 },
    BLACK  = { 55, 55, 55 }
}
