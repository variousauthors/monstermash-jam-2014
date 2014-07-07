return function(world)
  local fsm = FSM()

  fsm.addState({
      name       = "start",
    --init       = game.init,
      draw       = function ()
          world:draw()
      end,
      update     = function (dt)
          world:update(dt)
      end,
      keypressed = function (key)
          world:keypressed(key)

      end,
      keyreleased = function (key)
          world:keyreleased(key)
      end
  })

  fsm.addState({
      name       = "stop",
    --init       = game.init,
    --draw       = game.drawfunction,
    --update     = game.update,
    --keypressed = game.keypressed
  })

  -- start the game when the rock chooses a menu option
  fsm.addTransition({
      from      = "start",
      to        = "stop",
      condition = function ()
          return false
      end
  })

  return fsm
end
