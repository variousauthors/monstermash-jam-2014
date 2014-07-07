return function()
  local fsm = FSM()

  fsm.addState({
      name       = "start",
    --init       = game.init,
      draw       = function ()

      end,
      update     = function (dt)

      end,
      keypressed = function (key)

      end,
      keyreleased = function (key)
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
