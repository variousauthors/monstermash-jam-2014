
function Point(x, y)
    local x, y = x, y
    
    return {
        getX = function ()
            return x
        end,

        getY = function ()
            return y
        end,

        setX = function (n)
            x = n
        end,

        setY = function (n)
            y = n
        end
    }
end

function Vector(x, y)
    local p = Point(x, y)

    p.length = function ()
        return math.sqrt(p.getX() ^ 2 + p.getY() ^ 2)
    end

    -- returns a new vector with a length of 1
    p.to_unit = function ()
        local mag = p.length()

        return Vector(p.getX() / mag, p.getY() / mag)
    end

    return p
end
