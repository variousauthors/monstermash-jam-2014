
return function (entity, controls)
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)
    local cannon     = FSM(true, "x_buster", entity.get("name"))
    local cool_down  = 10
    local relax      = 20
    local mega_blast = 40

    local ammo = {
        pellet = 3,
        charge = 1
    }

    cannon.incrementAmmo = function (ammo_type)
        if ammo_type == "blast" or ammo_type == "mega_blast" then
            ammo_type = "charge"
        end

        ammo[ammo_type] = ammo[ammo_type] + 1
    end

    local decrementAmmo = function (ammo_type)
        ammo[ammo_type] = ammo[ammo_type] - 1
    end

    cannon.addState({
        name = "inactive",
        init = function()
            local id = entity.get("id")
            Sound:stop("charge", id)
        end
    })

    cannon.addState({
        name = "pellet",
        init = function ()
            local id = entity.get("id")
            Sound:stop("charge", id)
            Sound:run("pellet", id)
            cannon.set("shoot")
            decrementAmmo("pellet")
        end
    })

    cannon.addState({
        name = "blast",
        init = function ()
            local id = entity.get("id")
            Sound:stop("charge", id)
            Sound:run("blast", id)
            cannon.set("shoot")
            decrementAmmo("charge")
        end
    })

    cannon.addState({
        name = "mega_blast",
        init = function ()
            local id = entity.get("id")
            Sound:stop("charge", id)
            Sound:run("mega_blast", id)
            cannon.set("shoot")
            decrementAmmo("charge")
        end
    })

    cannon.addState({
        name = "charging",
        init = function()
            local id = entity.get("id")
            Sound:run("charge", id)
        end,
        update = function (dt)
            if cannon.getCount() > mega_blast then
                cannon.set("mega_blast")
            end
        end
    })

    cannon.addState({
        name = "cool_down"
    })

    cannon.addTransition({
        from = "inactive",
        to = "pellet",
        condition = function ()
            return ammo["pellet"] > 0 and not entity.get("shocked") and entity.pressed(SHOOT)
        end
    })

    cannon.addTransition({
        from = "inactive",
        to = "charging",
        condition = function ()
            return ammo["charge"] > 0 and not entity.get("shocked") and entity.holding(SHOOT)
        end
    })

    cannon.addTransition({
        from = "inactive",
        to = "cool_down",
        condition = function ()
            return ammo["charge"] > 0 and ammo["pellet"] == 0 and not entity.get("shocked") and entity.pressed(SHOOT)
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
            return ammo["pellet"] > 0 and cool_down <= cannon.getCount() and cannon.getCount() <= relax and entity.pressed(SHOOT)
        end
    })

    cannon.addTransition({
        from = "charging",
        to = "blast",
        condition = function ()
            return not entity.get("shocked") and entity.released(SHOOT) and not cannon.isSet("mega_blast")
        end
    })

    cannon.addTransition({
        from = "blast",
        to = "inactive",
        condition = function () return true end
    })

    cannon.addTransition({
        from = "charging",
        to = "mega_blast",
        condition = function ()

            return not entity.get("shocked") and entity.released(SHOOT) and cannon.isSet("mega_blast")
        end
    })

    cannon.addTransition({
        from = "charging",
        to = "inactive",
        condition = function ()

            return entity.get("shocked")
        end
    })

    cannon.addTransition({
        from = "mega_blast",
        to = "inactive",
        condition = function () return true end
    })


    cannon.start("inactive")

    return cannon
end

