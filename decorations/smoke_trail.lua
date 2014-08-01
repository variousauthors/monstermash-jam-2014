if not DecorationFactory then require("decorations/decoration_factory") end

local smoke_dimension = 10

return DecorationFactory(smoke_dimension, smoke_dimension, global.z_orders.decorations, COLOR.GREY, "smoke_trail", {
    update = function (self, dt)
        self.setY(self.getY() - 10*dt)
        -- update the animation

        -- update the timer
        if self.isOver() then
            self._unregister()
        end
    end,
    draw = function (self, owner)
        local facing = owner.get("facing") == LEFT and RIGHT or LEFT
        local sign = ( facing == RIGHT ) and 1 or -1

        love.graphics.setColor({ rng:random(0, 255), rng:random(0, 255), rng:random(0, 255) })
        love.graphics.rectangle("fill", self.getX(), self.getY(), self.getWidth(), self.getHeight())

        --  + sign*(1.8*smoke_dimension)
        love.graphics.setColor(COLOR.WHITE)
    end
})

