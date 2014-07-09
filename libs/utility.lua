require('love.math')

local i = require("vendor/inspect/inspect")
inspect = function (a, b)
    print(i.inspect(a, b))
end

stringspect = i.inspect

function math.round(val, decimal)
  local exp = decimal and 10^decimal or 1
  return math.ceil(val * exp - 0.5) / exp
end

function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

function table.find(table, element)
  for k, v in pairs(table) do
    if (v == element) then return k end
  end
end

rng = love.math.newRandomGenerator(love.timer.getTime())

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

-- constants for checking types
TYPE = {
    NUMBER   = "number",
    TABLE    = "table",
    FUNCTION = "function"
}
