

-- Requiring files

Settings        = require "src.conf.settings"
Assets          = require "src.systems.assets"
Camera          = require "src.systems.camera"
FishManager     = require "src.systems.fish_manager"

Particle        = require "src.classes.particle"
ParticleManager = require "src.systems.particle_manager"

HUD             = require "src.ui.hud"
MainMenu        = require "src.ui.mainmenu"
Market          = require "src.ui.market"
fishDefs        = require "src.conf.fish_defs"

Fish            = require "src.classes.fish"



local mW, mH, wW, wH, scale


local timer = 0
local score = 0
local catchFeedback = nil
local player = {
    x = 0,
    y = 0,
    rotation = 0,
}
local baseY = 0
local ox, oy = 0, 0



-- Helpers

local function distFromCenter(x, y)
    return (mW/2) - x, (mH/2) - y
end

local function maxDepth(depths)
    return -(depths[1].getHeight() * #depths - mH + 10)
end

-- Fish Catch Logic

local function catchFish(idx)
    local f = FishManager.fish[idx]
    local def = f.def

    score = score + def.points

    local img = def.img
    ParticleManager.burst(
        (f.x + img:getWidth() / 2) * scale,
        (f.y + Camera.offsetY + img:getHeight() / 2 ) * scale,
        def.color[1], def.color[2], def.color[3]
    )

    catchFeedback = {
        text = "You have caught a ".. def.name
        .. " [".. def.rarity .. "] worth " ..def.points .. " points!",
        timer = 2.5,
        color = def.color,
    }

    table.insert(FishManager.inventory, FishManager.fish[idx])
    FishManager.remove(idx)
end


function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())

    mW, mH = Settings.MAP_W, Settings.MAP_H
    scale = Settings.SCALE
    wW, wH = mW * scale, mH * scale

    love.window.setMode(wW, wH)

    Assets.load()

    local md = maxDepth(Assets.depths)
    Camera.init(md)
    FishManager.init()
    ParticleManager.init()

    MainMenu.init(wW, wH)
end