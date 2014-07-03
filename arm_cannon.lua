
return function (entity, controls)
    local LEFT, RIGHT, JUMP, SHOOT, DASH = unpack(controls)
    local cannon     = FSM()
    local cool_down  = 10
    local relax      = 20
    local mega_blast = 40

    cannon.addState({
        name = "inactive"
    })

    cannon.addState({
        name = "pellet",
        init = function ()
            cannon.set("shoot")
        end
    })

    cannon.addState({
        name = "blast",
        init = function ()
            cannon.set("shoot")
        end
    })

    cannon.addState({
        name = "mega_blast",
        init = function ()
            cannon.set("shoot")
        end
    })

    cannon.addState({
        name = "charging",
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
            return entity.pressed(SHOOT)
        end
    })

    cannon.addTransition({
        from = "inactive",
        to = "charging",
        condition = function ()
            return entity.holding(SHOOT)
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
            return cool_down <= cannon.getCount() and cannon.getCount() <= relax and entity.pressed(SHOOT)
        end
    })

    cannon.addTransition({
        from = "cool_down",
        to = "pellet"
    })

    cannon.addTransition({
        from = "charging",
        to = "blast",
        condition = function () return not entity.get(SHOOT) end
    })

    cannon.addTransition({
        from = "blast",
        to = "inactive",
        condition = function () return true end
    })

    cannon.addTransition({
        from = "charging",
        to = "mega_blast",
        condition = function () return false end
    })

    cannon.addTransition({
        from = "mega_blast",
        to = "inactive",
        condition = function () return true end
    })


    cannon.start("inactive")

    return cannon
end

