
-- @param ... any number of constructors, or a string or a function that returns a string
return function (x, y, ...)
    local offset = { x = x, y = y }
    local text, func, components = nil, nil, {}
    local image

    -- by default the component draws its components,
    -- but leaf components will draw something else
    local draw_logic = function (x, y)
        for key, value in pairs(components) do
            value.draw(x, y)
        end
    end

    -- iterate over the args, until we hit a string
    -- or a function
    -- a component either: shows a string, or shows the result of a function
    -- call, and shows all of its components
    -- We call these: static, dynamic, and composite components
    local initialize = function (...)
        for i, arg in ipairs({...}) do

            if type(arg) == "string" then
                draw_logic = function (x, y)
                    love.graphics.print(arg, x, y)
                end

                return

            -- later we should maybe replace func with a free standing
            -- draw function, rather than a function that returns a string.
            -- That way we will be able to have coin and flower pictures
            elseif type(arg) == "function" then
                -- close around out offsets
                draw_logic = arg
                return

            elseif type(arg) == "table" then
                table.insert(components, arg)
            end
        end
    end

    -- @params frame_x,_y the position of the parent component
    local draw = function (frame_x, frame_y)
        draw_logic(frame_x + offset.x, frame_y + offset.y)
    end

    initialize(unpack({...}))

    return {
        draw   = draw,
        offset = offset
    }
end
