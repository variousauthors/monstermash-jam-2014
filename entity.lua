
Entity = (function ()
    local entity_id = 1

    return function (x, y, w, h)
        local read_only  = {}
        local read_write = { }

        local p = Point(x, y)

        read_only["id"]  = entity_id
        entity_id = entity_id + 1

        local get = function (key)
            local value = read_only[key]

            if not value then
                value = read_write[key]
            end

            return value
        end

        local set = function (key, value)
            read_write[key] = value
        end

        local getFilterFor = function(key)
            return function(other)
                return ent.get(key)
            end
        end

        local getBoundingBox = function()
            return p.getX(), p.getY(), w, h
        end

        local tic     = function () end
        local cleanup = function () end

        return {
            get     = get,
            set     = set,
            tic     = tic,
            cleanup = cleanup,
            getX    = p.getX,
            getY    = p.getY,
            setX    = p.setX,
            setY    = p.setY,
            getFilterFor = getFilterFor,
            getBoundingBox = getBoundingBox
        }
    end
end)()

