
-- bullet returns a constructor for a bullet type
BulletFactory = function (speed, acceleration, w, h, damage, color, name)

    return function (x, y, owner, direction)
        local entity         = Entity(x, y - h/2, w, h)
        local obstacleFilter = entity.getFilterFor('isObstacle')
        local max_speed      = speed
        local acceleration   = acceleration
        local current_speed  = 0

        entity.set('isBullet', true)
        entity.set("owner_id", owner.get("id"))
        entity.set("damage", damage)

        entity.draw = function ()
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", entity.getX(), entity.getY(), w, h)
            love.graphics.setColor(COLOR.WHITE)
        end

        entity.update = function (dt, world)
            current_speed = math.min(current_speed + acceleration, max_speed)

            entity.setX(entity.getX() + direction*current_speed)
            world.bump:move(entity, entity.getX(), entity.getY())

            entity.resolveObstacleCollide(world)

            -- remove bullets as they fly off the screen
            if entity.getX() > global.screen_width or entity.getX() < 0 then
                owner.incrementAmmo(name)
                entity._unregister()
            end

        end

        entity.resolveObstacleCollide = function(world)
            local new_x, new_y = entity.getX(), entity.getY()
            local cols, len = world.bump:check(entity, new_x, new_y, obstacleFilter)

            if len == 0 then
                world.bump:move(entity, new_x, new_y)
            else

                owner.incrementAmmo(name)
                entity._unregister()
            end
        end

        entity.resolveEntityCollide = function ()
            owner.incrementAmmo(name)

            -- only pellets vanish after a hit
            if name == "pellet" then
                entity._unregister()
            end
        end

        return entity
    end
end
