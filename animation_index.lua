
animation_index = {

    standing = { 1, 1 },

    to_recoil = { 1,2 },
    recoil    = { 2,2 },

    to_jumping          = { '1-3', 3 },
    jumping             = { 3,3 },
    to_falling          = { '3-5', 3 },
    falling             = { 5,3 },
    falling_to_standing = { '6-7', 3 },

    to_running   = { 1,5 },
    running      = { '2-11', 5 },
    from_running = { 1,5 },

    to_dashing   = { 1,7 },
    dashing      = { 2,7 },
    from_dashing = { 1,7 },

    to_climbing      = { '1-2', 9 },
    climbing         = { 3,9 },
    climbing_to_jump = { '4-5',9 },

    to_hurt = { 1,11 },
    hurt    = { '2-11', 11 },

    death = { 1,11 }
}

animation_index.get = function (string)
    return unpack(animation_index[string])
end

return animation_index
