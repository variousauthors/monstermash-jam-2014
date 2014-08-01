
-- bullet returns a constructor for a bullet type
DecorationFactory = function (w, h, z, color, name, callbacks)

    local obj = {
        WIDTH  = w,
        HEIGHT = h
    }

    local init = function (x, y, owner)
        local entity = Entity(x, y - h/2, w, h, z)
        local speed, direction
        local timer = 0

        entity.set('isDecoration', true)
        entity.set("owner_id", owner.get("id"))

        entity.draw = function ()
            callbacks["draw"](entity, owner)
        end

        entity.update = function (dt)
            timer = timer + dt
            callbacks["update"](entity, dt)
        end

        local isOver = function ()
            return timer > 1
        end

        entity.isOver = function ()
            if callbacks["isOver"] then
                return callbacks["isOver"](entity, owner)
            else
                return isOver()
            end
        end

        return entity
    end

    setmetatable(obj, {
        __call = function (_, ...) return init(...) end
    })

    return obj
end
