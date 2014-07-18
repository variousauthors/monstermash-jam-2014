
local animation_index = {

    standing = { 1, 1 },

    to_recoil = { 1,2 },
    recoil    = { 2,2 },

    to_jumping          = { '1-3', 3 },
    jumping             = { 3,3 },
    to_falling          = { '4-5', 3 },
    falling             = { 5,3 },
    falling_to_standing = { '6-7', 3 },

    to_running   = { 1,5 },
    running      = { '2-11', 5 },
    from_running = { 1,5 },

    to_dashing   = { 1,7 },
    dashing      = { 2,7 },
    from_dashing = { 1,7 },

    -- I took out one frame of climbing because it greatly complicates things
    -- when megeman goes from jumping into a wall to climbing, he goes briefly
    -- to a frame that is facing the wall and can shoot toward the wall, before
    -- hitting the facing away from the wall climbing stuff. I'm not down with
    -- that, sorry rock
    -- to_climbing      = { '1-2', 9 },
    to_climbing      = { 2, 9 },
    climbing         = { 3,9 },
    climbing_to_jump = { '4-5',9 },

    to_hurt = { 1,11 },
    hurt    = { '2-11', 11 },

    death = { '1-4', 12 }
}

local shooting_index = {

    standing = { 1, 2 },

    to_recoil = { 1,3 },
    recoil    = { 2,3 },

    to_jumping          = { '1-3', 4 },
    jumping             = { 3,4 },
    to_falling          = { '4-5', 4 },
    falling             = { 5,4 },
    falling_to_standing = { '6-7', 4 },

    to_running   = { 1,6 },
    running      = { '2-11', 6 },
    from_running = { 1,6 },

    to_dashing   = { 1,8 },
    dashing      = { 2,8 },
    from_dashing = { 1,8 },

    -- I took out one frame of climbing because it greatly complicates things
    -- when megeman goes from jumping into a wall to climbing, he goes briefly
    -- to a frame that is facing the wall and can shoot toward the wall, before
    -- hitting the facing away from the wall climbing stuff. I'm not down with
    -- that, sorry rock
    -- to_climbing      = { '1-2', 9 },
    to_climbing      = { 2, 10 },
    climbing         = { 3,10 },
    climbing_to_jump = { '4-5',10 },

    to_hurt = { 1,11 },
    hurt    = { '2-11', 11 },

    death = { '1-4', 12 }
}


animation_index.get = function (string, shooting)
    local frames

    if shooting then
        frames = shooting_index[string]
    else
        frames = animation_index[string]
    end

    return unpack(frames)
end

return animation_index
