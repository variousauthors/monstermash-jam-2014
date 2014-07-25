
-- bullet returns a constructor for a bullet type
DecorationFactory = function (w, h, color, name, callbacks)

    return function (x, y, owner)
        local entity = Entity(x, y - h/2, w, h)
        local speed, direction
        local timer = 0

        entity.set('isDecoration', true)
        entity.set("owner_id", owner.get("id"))

        entity.draw = function ()
            callbacks["draw"](entity, dt)
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
end
