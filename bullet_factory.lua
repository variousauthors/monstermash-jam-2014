
-- bullet returns a constructor for a bullet type
BulletFactory = function (speed, w, h, damage, color, name)

    return function (x, y, owner)
        local entity = Entity(x, y - h/2, w, h)

        local direction = (owner.get("facing") == LEFT and -1 or 1)

        if owner.get(name) then
            local count = owner.get(name)
            owner.set(name, count + 1)
        else
            owner.set(name, 1)
        end

        entity.draw = function ()
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", entity.getX(), entity.getY(), w, h)
            love.graphics.setColor(COLOR.WHITE)
        end

        entity.update = function (dt)
            entity.setX(entity.getX() + direction*speed)

            -- remove bullets as they fly off the screen
            if entity.getX() > global.screen_width or entity.getX() < 0 then
                local count = owner.get(name)
                owner.set(name, count - 1)
                entity._unregister()
            end
        end

        return entity
    end
end
