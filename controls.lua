local controls = {}

controls["statemappings"] = {
    p1_left   = {"k_left", "j1_dpleft", "j1_leftx-0.5"},
    p1_right  = {"k_right", "j1_dpright", "j1_leftx+0.5"},
    p1_jump   = {"k_z", "j1_a"},
    p1_shoot  = {"k_x", "j1_x"},
    p1_dash   = {"k_lshift", "j1_rightshoulder", "j1_triggerright+0.95"},
    p2_left   = {"j2_dpleft", "j2_leftx-0.5"},
    p2_right  = {"j2_dpright", "j2_leftx+0.5"},
    p2_jump   = {"j2_a"},
    p2_shoot  = {"j2_x"},
    p2_dash   = {"j2_rightshoulder", "j2_triggerright+0.95"},
    p3_left   = {"j3_dpleft", "j3_leftx-0.5"},
    p3_right  = {"j3_dpright", "j3_leftx+0.5"},
    p3_jump   = {"j3_a"},
    p3_shoot  = {"j3_x"},
    p3_dash   = {"j3_rightshoulder", "j3_triggerright+0.95"},
    p4_left   = {"j4_dpleft", "j4_leftx-0.5"},
    p4_right  = {"j4_dpright", "j4_leftx+0.5"},
    p4_jump   = {"j4_a"},
    p4_shoot  = {"j4_x"},
    p4_dash   = {"j4_rightshoulder", "j4_triggerright+0.95"},
    pause     = {"k_p"}
}

-- Generate player controls
-- controls["p#"] = {LEFT, RIGHT, JUMP, SHOOT, DASH}
local players = 4
for i=1,players do
    local p = 'p'..i
    controls[p] = {p..'_left', p..'_right', p..'_jump', p..'_shoot', p..'_dash'}
end

return controls
