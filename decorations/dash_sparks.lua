if not DecorationFactory then require("decorations/decoration_factory") end

local sparks_width    = 20
local sparks_height   = 10

return DecorationFactory(sparks_width, sparks_height, global.z_orders.decorations, COLOR.YELLOW, "dash_sparks", {
    update = function (self, dt)
        -- update the animation

        -- update the timer
        if self.isOver() then
            self._unregister()
        end
    end,
    draw = function (self, owner)
        local facing = owner.getFacing() == LEFT and RIGHT or LEFT
        local sign = ( facing == RIGHT ) and 1 or -1

        love.graphics.setColor({ rng:random(0, 255), rng:random(0, 255), rng:random(0, 255) })
        love.graphics.rectangle("fill", self.getX(), self.getY(), self.getWidth(), self.getHeight())

        --  + sign*(sparks_width)

        love.graphics.setColor(COLOR.WHITE)
    end,
    isOver = function (self, owner)
        return not owner.isDashing()
    end
})

