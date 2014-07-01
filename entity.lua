
Entity = (function ()
    local entity_id = 1

    return function ()
        local read_only  = {}
        local read_write = { }

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

        local tic = function () end

        return {
            get = get,
            set = set,
            tic = tic
        }
    end
end)()

