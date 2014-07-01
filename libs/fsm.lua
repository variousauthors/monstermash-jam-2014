
-- USEAGE
--
--  state_machine = FSM()

--  -- a state will inherit any method it did not
--  -- declare from the previous state
--  state_machine.addStates({
    --  {
    --      name       = "start",
    --      init       = function () end,
    --      draw       = function () end,
    --      update     = function () end,
    --      keypressed = function () end
    --  }, {
    --      name       = "stop",
    --      init       = function () end,
    --      draw       = function () end,
    --      update     = function () end,
    --      keypressed = function () end
    --  }
--  })

--  state_machine.addTransitions({
    --  {
    --      from = "start",
    --      to = "run",
    --      condition = function ()
    --          return true
    --      end
    --  }
--  })

FSM = function ()
    local states        = {}
    local current_state = { name = "nil" }

    local transitionTo = function (next_state)
        -- TODO currently no states have cleanup steps, and I'm debating whether they need'em
        -- most "cleanup steps" could be their own states with automatic transitions...
        -- but that is kind of wordy... I'll decide after a refactor
        if current_state.cleanup then current_state.cleanup() end

        current_state = states[next_state]
        current_state.variables = {}

        if current_state.init then current_state.init() end
    end

    local update = function (dt)

        -- iterate over the transitions for the current state
        local next_state = {}

        for i, transition in ipairs(current_state.transitions) do
            if transition.condition() then
                table.insert(next_state, transition.to)
            end
        end

        if #next_state == 1 then
            transitionTo(unpack(next_state))
        elseif #next_state > 1 then
            print("AMBIGUITY!")
            inspect(next_state)
            -- exception!
            -- ambiguous state transition
        end

        if current_state.update then current_state.update(dt) end
    end

    local draw = function ()
        if current_state.draw then current_state.draw() end
    end

    local keypressed = function (key)
        -- transition to draw or win
        state_machine.set(key)

        if current_state.keypressed then current_state.keypressed(key) end
    end

    local keyreleased = function (key)
        -- transition to draw or win
        state_machine.unset(key)

        if current_state.keyreleased then current_state.keyreleased(key) end
    end

    local textinput = function (key)
        if current_state.textinput then current_state.textinput(key) end
    end

    local addState = function(state)
        states[state.name] = {
            name        = state.name,
            init        = state.init,
            update      = state.update,
            draw        = state.draw,
            keypressed  = state.keypressed,
            keyreleased = state.keyreleased,
            textinput   = state.textinput,
            transitions = {},
            variables   = {}
        }

        return self
    end

    local addTransition = function(transition)
        table.insert(states[transition.from].transitions, {
            to        = transition.to,
            condition = transition.condition,
        })
    end

    local start = function (name)
        if name == nil then name = "start" end
        transitionTo(name)
    end

    local set = function (key)
        current_state.variables[key] = true
    end

    local unset = function (key)
        current_state.variables[key] = false
    end

    local isSet = function (key)
        local result = false

        if current_state.variables[key] ~= nil then
            result = current_state.variables[key]
        end

        return result
    end

    local is = function (name)
        return current_state.name == name
    end

    return {
        start         = start,
        update        = update,
        keypressed    = keypressed,
        keyreleased   = keyreleased,
        textinput     = textinput,
        draw          = draw,
        addState      = addState,
        addTransition = addTransition,
        unset         = unset,
        set           = set,
        isSet         = isSet,
        is            = is
    }
end
