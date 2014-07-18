local Sound = require("libs/soundman").new()

Sound:add("pellet", "playSound", "assets/sfx/pellet.mp3", "sfx", 1, "static")
Sound:add("blast", "playSound", "assets/sfx/blast.mp3", "sfx", 1, "static")
Sound:add("mega_blast", "playSound", "assets/sfx/mega_blast.mp3", "sfx", 1, "static")
Sound:add("charge", "playSoundRegionLoop", "assets/sfx/charge.mp3", "sfx", 1, "static", 3.114910, 4.628900)
Sound:add("jump", "playSound", "assets/sfx/jump.mp3", "sfx", 1, "static")
Sound:add("wall_jump", "playSound", "assets/sfx/jump.mp3", "sfx", 1, "static")
Sound:add("dash", "playSound", "assets/sfx/dash.mp3", "sfx", 1, "static")
Sound:add("damaged", "playSound", "assets/sfx/damaged.mp3", "sfx", 1, "static")
Sound:add("destroyed", "playSound", "assets/sfx/destroyed.mp3", "sfx", 1, "static")

Sound:add("mainMusic","playSoundRegionLoop", "assets/music/bossbattle.mp3", "music", 4.25490, 32.431358)

return Sound
