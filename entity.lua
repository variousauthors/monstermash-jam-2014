
Entity = (function ()
    local entity_id = 1

    return function ()
        local read_only  = {}
        read_only["id"]  = entity_id
        entity_id = entity_id + 1

        local get = function (key)
            return read_only[key]
        end

        local tic = function () end

        return {
            get = get,
            tic = tic
        }
    end
end)()

