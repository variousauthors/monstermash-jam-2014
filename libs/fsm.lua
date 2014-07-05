
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

FSM = function (verbose)
    local states        = {}
    local current_state = { name = "nil" }

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

    local getCount = function ()
        return current_state.count
    end

    local transitionTo = function (next_state)
        -- TODO currently no states have cleanup steps, and I'm debating whether they need'em
        -- most "cleanup steps" could be their own states with automatic transitions...
        -- but that is kind of wordy... I'll decide after a refactor
        if current_state.cleanup then current_state.cleanup() end

        current_state           = states[next_state]
        current_state.variables = {}
        current_state.count     = 0

        if current_state.init then current_state.init() end
    end

    local stateTransition = function ()
        -- iterate over the transitions for the current state
        local next_state = {}

        for i, transition in ipairs(states["any"].transitions) do
            if transition.condition and transition.condition() then
                table.insert(next_state, transition.to)
            end
        end

        -- if any of the "any" state transitions is good to go,
        -- then we don't need to check for any other state transitions
        if #next_state == 0 then
            for i, transition in ipairs(current_state.transitions) do
                if transition.condition and transition.condition() then
                    table.insert(next_state, transition.to)
                end
            end
        end

        if #next_state == 1 then
            transitionTo(unpack(next_state))
        elseif #next_state > 1 then
            print("AMBIGUITY!")
            print("  in " .. current_state.name)
            inspect(next_state)
            -- exception!
            -- ambiguous state transition
        end

        current_state.count = current_state.count + 1

        if verbose then
            print("in " .. current_state.name)
        end
    end

    -- in update, if a key is "set" then it is "held". It was pressed
    -- in the keypressed function
    local update = function (dt)
        stateTransition()

        if current_state.update then current_state.update(dt) end
    end

    local keypressed = function (key)
        stateTransition()

        set(key)

        if current_state.keypressed then current_state.keypressed(key) end
    end

    local keyreleased = function (key)
        stateTransition()

        unset(key)

        if current_state.keyreleased then current_state.keyreleased(key) end
    end

    local draw = function ()
        if current_state.draw then current_state.draw() end
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
        if transition.to == "any" then
            print("WARNING")
            print("attempt to add transition to 'any' will fail")
            return
        end

        table.insert(states[transition.from].transitions, {
            to        = transition.to,
            condition = transition.condition,
        })
    end

    local start = function (name)
        if name == nil then name = "start" end
        transitionTo(name)
    end

    local getState = function ()
        return current_state.name
    end

    addState({
        name = "any"
    })

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
        is            = is,
        getCount      = getCount,
        getState      = getState
    }
end
