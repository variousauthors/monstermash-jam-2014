
-- bullet returns a constructor for a bullet type
BulletFactory = function (speed, w, h, z, damage, color, name, options)

    return function (x, y, owner, direction)
        local entity         = Entity(x, y - h/2, w, h, z)
        local obstacleFilter = entity.getFilterFor('isObstacle')
        local max_speed      = speed
        local current_speed  = 0
        local acceleration   = 0.25

        entity.set('isBullet', true)
        entity.set("owner_id", owner.get("id"))
        entity.set("damage", damage)

        local incrementAmmo = function ()
            if options ~= nil and options["increment_ammo"] == false then
                -- NOP
            else
                owner.incrementAmmo(name)
            end
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
                incrementAmmo(name)
                entity._unregister()
            end

        end

        entity.resolveObstacleCollide = function(world)
            local new_x, new_y = entity.getX(), entity.getY()
            local cols, len = world.bump:check(entity, new_x, new_y, obstacleFilter)

            if len == 0 then
                world.bump:move(entity, new_x, new_y)
            else
                if options and options["onCollision"] then
                    options["onCollision"](cols[1], entity)
                end

                incrementAmmo(name)
                entity._unregister()
            end
        end

        entity.resolveEntityCollide = function ()
            incrementAmmo(name)

            -- pellets vanish after a hit
            -- there should be an option for "vanish on hit"
            if name == "pellet" or (options and options["vanish_on_hit"] == true) then
                entity._unregister()
            end
        end

        return entity
    end
end
