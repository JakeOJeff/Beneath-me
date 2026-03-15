

local Settings = {}

-- World / window
Settings.MAP_W          = 140
Settings.MAP_H          = 88
Settings.SCALE          = 10

-- Scroll / physics
Settings.INITIAL_OFFSET_Y      = -10
Settings.FRICTION              = 0.98
Settings.DEPTH_ZONE_THRESHOLD  = -70

-- Fish spawning
Settings.FISH_SPAWN_INTERVAL   = 4
Settings.MAX_FISH              = 12

-- Asset paths
Settings.FONTS = {
    jersey = "fonts/jersey.ttf",
}

Settings.FONT_SIZES = {
    title = 100,
    h  = 36,
    sm = 24,
}

return Settings