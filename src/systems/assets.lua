

local Assets = {}

function Assets.load()
    -- Sky / water layers
    Assets.stableSky = love.graphics.newImage("assets/watertop/stable.png")
    Assets.layers    = {}
    for i = 1, 4 do
        table.insert(Assets.layers, love.graphics.newImage("assets/watertop/" .. i .. ".png"))
    end
    Assets.buoy   = love.graphics.newImage("assets/watertop/buoy.png")

    -- Depth backgrounds
    Assets.depths = {
        love.graphics.newImage("assets/depths/1.png"),
        love.graphics.newImage("assets/depths/2.png"),
        love.graphics.newImage("assets/depths/3.png"),
        love.graphics.newImage("assets/depths/4.png"),

    }

    -- UI elements
    Assets.ruler   = love.graphics.newImage("assets/depth-bar.png")
    Assets.pointer = love.graphics.newImage("assets/pointer.png")

    -- Fonts  (screen-space pixel sizes)
    Assets.font = {
        h  = love.graphics.newFont(Settings.FONTS.jersey, Settings.FONT_SIZES.h),
        sm = love.graphics.newFont(Settings.FONTS.jersey, Settings.FONT_SIZES.sm),
    }

    -- Load fish images into their definitions
    for _, fd in ipairs(fishDefs) do
        fd.img = love.graphics.newImage(fd.imgPath)
    end
end

return Assets