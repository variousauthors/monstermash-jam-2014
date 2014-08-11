if not BulletFactory then require("bullet_factory") end

-- TODO need to be able to "pick up" new weapons
-- and switch between weapons

return function (entity, controls)
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)
    local cannon      = FSM(false, "x_buster", entity.get("name"))
    local cool_down   = 10
    local relax       = 20
    local mega_blast  = 40
    local fat_gun_dim = 3

    local IcePellet = BulletFactory(6, 2, 2, global.z_orders.bullets, 1, { 100, 150, 200 }, "pellet", {
        increment_ammo = false
    })

    local Pellet    = BulletFactory(5, 6, 6, global.z_orders.bullets, 1, { 100, 150, 200 }, "pellet", {
        increment_ammo = false,
        vanish_on_hit = true,
        onCollision = function (col, bullet)
            local tx, ty, nx, ny = col:getTouch()
            local direction = nx

            entity.register(IcePellet(bullet.getX() + direction*10, bullet.getY(), entity, direction))
        end
    })
    -- local Pellet    = BulletFactory(5, 4, 4, global.z_orders.bullets, 1, COLOR.YELLOW, "pellet")
    local Blast     = BulletFactory(6, 20, 5, global.z_orders.bullets, 2, COLOR.GREEN, "blast")
    local MegaBlast = BulletFactory(5, 15, 20, global.z_orders.bullets, 3, COLOR.RED, "mega_blast")

    local MEGA_BLAST = "mega_blast"
    local SHOCKED    = "shocked"

    cannon.register_keys = { MEGA_BLAST, SHOCKED }

    local Bullets = {
        pellet     = Pellet,
        blast      = Blast,
        mega_blast = MegaBlast
    }

    local Ammo = {
        pellet = 16,
        --pellet = 3,
        charge = 1
    }

    local addBullet = function (ammo_type, ammo, Factory)
        Bullets[ammo_type] = Factory
        Ammo[ammo_type] = ammo
    end

    local resolveShoot = function ()
        local offset       = entity.getWidth()
        local bullet
        local direction = (entity.getFacing() == LEFT and -1 or 1)

        if entity.getFacing() == LEFT then
            offset = 0 - fat_gun_dim*2
        end

        return Bullets[cannon.getState()](entity.getX() + offset, entity.getY() + 1*entity.getHeight()/3 + fat_gun_dim/2, entity, direction)
    end

    cannon.incrementAmmo = function (ammo_type)
        if ammo_type == "blast" or ammo_type == "mega_blast" then
            ammo_type = "charge"
        end

        Ammo[ammo_type] = Ammo[ammo_type] + 1
    end

    local decrementAmmo = function (ammo_type)
        Ammo[ammo_type] = Ammo[ammo_type] - 1
    end

    cannon.addState({
        name = "inactive",
        init = function()
            local id = entity.getId()
            Sound:stop("charge", id)
        end
    })

    cannon.addState({
        name = "pellet",
        init = function ()
            local id = entity.getId()
            Sound:stop("charge", id)
            Sound:run("pellet", id)
            cannon.set("shoot")
            entity.register(resolveShoot())
            decrementAmmo("pellet")
        end,
    })

    cannon.addState({
        name = "blast",
        init = function ()
            local id = entity.getId()
            Sound:stop("charge", id)
            Sound:run("blast", id)
            cannon.set("shoot")
            entity.register(resolveShoot())
            decrementAmmo("charge")
        end
    })

    cannon.addState({
        name = "mega_blast",
        init = function ()
            local id = entity.getId()
            Sound:stop("charge", id)
            Sound:run("mega_blast", id)
            cannon.set("shoot")
            entity.set(MEGA_BLAST, false)
            entity.register(resolveShoot())
            decrementAmmo("charge")
        end
    })

    cannon.addState({
        name = "charging",
        init = function()
            local id = entity.getId()
            Sound:run("charge", id)
        end,
        update = function (dt)
            if cannon.getCount() > mega_blast then
                entity.set(MEGA_BLAST, true)
            end
        end
    })

    cannon.addState({
        name = "primed"
    })

    cannon.addState({
        name = "cool_down"
    })

    cannon.addTransition({
        from = "inactive",
        to = "pellet",
        condition = function ()
            return Ammo["pellet"] > 0 and not entity.get(SHOCKED) and entity.pressed(SHOOT)
        end
    })

    cannon.addTransition({
        from = "inactive",
        to = "charging",
        condition = function ()
            return Ammo["charge"] > 0 and not entity.get(SHOCKED) and entity.holding(SHOOT)
        end
    })

    cannon.addTransition({
        from = "inactive",
        to = "cool_down",
        condition = function ()
            return Ammo["charge"] > 0 and Ammo["pellet"] == 0 and not entity.get(SHOCKED) and entity.pressed(SHOOT)
        end
    })

    cannon.addTransition({
        from = "pellet",
        to = "cool_down",
        condition = function()
            return true
        end
    })

    cannon.addTransition({
        from = "cool_down",
        to = "inactive",
        condition = function ()
            return cannon.getCount() > relax
        end
    })

    cannon.addTransition({
        from = "cool_down",
        to = "pellet",
        condition = function ()
            return Ammo["pellet"] > 0 and cool_down <= cannon.getCount() and cannon.getCount() <= relax and entity.pressed(SHOOT)
        end
    })

    cannon.addTransition({
        from = "charging",
        to = "inactive",
        condition = function ()

            return entity.get(SHOCKED)
        end
    })

    cannon.addTransition({
        from = "charging",
        to = "primed",
        condition = function ()
            return not entity.get(SHOCKED) and entity.released(SHOOT)
        end
    })

    cannon.addTransition({
        from = "primed",
        to = "mega_blast",
        condition = function ()
            return entity.get(MEGA_BLAST)
        end
    })

    cannon.addTransition({
        from = "primed",
        to = "blast",
        condition = function ()
            return not entity.get(MEGA_BLAST)
        end
    })

    cannon.addTransition({
        from = "mega_blast",
        to = "inactive",
        condition = function () return true end
    })

    cannon.addTransition({
        from = "blast",
        to = "inactive",
        condition = function () return true end
    })

    cannon.start("inactive")

    return cannon
end

