
-- bullet returns a constructor for a bullet type
BulletFactory = function (speed, w, h, damage, color, name)

    return function (x, y, owner, direction)
        local entity = Entity(x, y - h/2, w, h)
        local obstacleFilter = entity.getFilterFor('isObstacle')
        entity.set('isBullet', true)
        entity.set("owner_id", owner.get("id"))
        entity.set("damage", damage)

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

        entity.update = function (dt, world)
            entity.setX(entity.getX() + direction*speed)
            world.bump:move(entity, entity.getX(), entity.getY())

            entity.resolveObstacleCollide(world)

            -- remove bullets as they fly off the screen
            if entity.getX() > global.screen_width or entity.getX() < 0 then
                entity.resolveEntityCollide()
            end
        end

        entity.resolveObstacleCollide = function(world)
            local new_x, new_y = entity.getX(), entity.getY()
            local cols, len = world.bump:check(entity, new_x, new_y, obstacleFilter)

            if len == 0 then
                world.bump:move(entity, new_x, new_y)
            else
                local col, tx, ty, sx, sy
                while len > 0 do
                    local col = cols[1]
                    print("other", col.other.get("id"))
                    print("this", entity.get("id"))
                    print("owner", owner.get("id"))
                    local tx, ty, nx, ny, sx, sy = col:getSlide()

                    entity.setX(tx)
                    entity.setY(ty)
                    world.bump:move(entity, entity.getX(), entity.getY())

                    cols, len = world.bump:check(entity, sx, sy, obstacleFilter)
                    if len == 0 then
                        entity.setX(sx)
                        entity.setY(sy)
                        world.bump:move(entity, entity.getX(), entity.getY())
                    end
                end

                entity.resolveEntityCollide()
            end
        end

        entity.resolveEntityCollide = function ()
            local count = owner.get(name)
            owner.set(name, count - 1)
            entity._unregister()
        end

        return entity
    end
end
