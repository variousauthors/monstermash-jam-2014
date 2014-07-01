if math.infinity == nil then
    math.infinity = "INF"
end

-- @param _construct: map args   --> object
-- @param tcurtsnoc_: map object --> args
Klass = function (_construct, tcurtsnoc_)
    local constructor

    local function copy(o)
        return constructor(tcurtsnoc_(o))
    end

    constructor = function (...)
        local instance = _construct(unpack({...}))

        instance.copy = function ()
            return copy(instance)
        end

        return instance
    end

    return constructor
end

-- a point!
Point = Klass((function ()
    local constructor = function (x, y)
        local x, y = x, y

        local instance = {
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
            end,
        }

        return instance
    end

    local copy = function (o)
        return o.getX(), o.getY()
    end

    return constructor, copy
end)())

-- a vector is a glorified point!
Vector = Klass((function ()
    local constructor

    _constructor = function (x, y)
        local p = Point(x, y)

        -- this is the "magnitude" of the vector, or its length as a line
        p.length = function ()
            return math.sqrt(p.getX() ^ 2 + p.getY() ^ 2)
        end

        p.getSlope = function ()
            local slope

            -- the slope is infinite
            if -0.1 < x and x < 0.1 then
                slope = math.infinity
            else
                slope = y / x
            end

            return slope
        end

        -- returns a new vector with a length of 1, for stuff
        p.to_unit = function ()
            local mag = p.length()

            if mag == 0 then return Vector(0, 0) end

            return Vector(p.getX() / mag, p.getY() / mag)
        end

        -- some operators like dot and plus. Write more as you need them
        p.dot = function (o)
            local x = p.getX() * o.getX()
            local y = p.getY() * o.getY()

            return constructor(x, y)
        end

        p.plus = function (o)
            local x = p.getX() + o.getX()
            local y = p.getY() + o.getY()

            return constructor(x, y)
        end

        return p
    end

    constructor = _constructor

    local copy = function (o)
        return o.getX(), o.getY()
    end

    return constructor, copy
end)())
