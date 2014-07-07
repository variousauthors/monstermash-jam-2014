
animation_index = {
    standing      = { 1, 1 },
    into_jumping  = { '2-4', 1 },
    jumping       = { 4,1 },
    into_falling  = { '4-6', 1 },
    falling       = { 6,1 },
    into_standing = { '7-8', 1 },
}

animation_index.get = function (string)
    return unpack(animation_index[string])
end

return animation_index
