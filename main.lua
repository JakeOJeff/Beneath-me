
Settings       = require("src.conf.settings")
Assets         = require("src.systems.assets")
Camera         = require("src.systems.camera")
FishManager    = require("src.systems.fish_manager")
Particle       = require("src.classes.particle")
ParticleManager= require("src.systems.particle_manager")
HUD            = require("src.ui.hud")
fishDefs       = require("src.conf.fish_defs")
Fish           = require("src.classes.fish")
-- Convenience aliases (set after load)
local mW, mH, wW, wH, scale

-- Game state
local timer         = 0
local score         = 0
local catchFeedback = nil
local player        = { x = 0, y = 0, rotation = 0 }
local baseY         = 0
local ox, oy        = 0, 0

-- ─────────────────────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────────────────────

local function distFromCenter(x, y)
    return (mW / 2) - x, (mH / 2) - y
end

local function maxDepth(depths)
    return -(depths[1]:getHeight() *  #depths - mH + 10)
end

-- ─────────────────────────────────────────────────────────────
--  Catch logic
-- ─────────────────────────────────────────────────────────────

local function catchFish(idx)
    local f   = FishManager.fish[idx]
    local def = f.def
    score = score + def.points

    -- particle burst in screen space
    local img = def.img
    -- local cx  = (f.x + img:getWidth()  / 2) * scale
    -- local cy  = (f.y + Camera.offsetY  + img:getHeight() / 2) * scale
    -- ParticleManager.burst(cx, cy, def.color[1], def.color[2], def.color[3])
    ParticleManager.burst((f.x + img:getWidth() /2 )* scale, (f.y + Camera.offsetY + img:getHeight() /2) * scale, def.color[1], def.color[2], def.color[3])

    catchFeedback = {
        text  = "+" .. def.points .. "  " .. def.name .. "!",
        timer = 2.5,
        color = def.color,
    }

    FishManager.remove(idx)
    -- -- Camera.returnToSurface()
    -- FishManager.clear()
end

-- ─────────────────────────────────────────────────────────────
--  love.load
-- ─────────────────────────────────────────────────────────────

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    math.randomseed(os.time())

    mW, mH = Settings.MAP_W, Settings.MAP_H
    scale  = Settings.SCALE
    wW, wH = mW * scale, mH * scale
    love.window.setMode(wW, wH)

    Assets.load()

    local md = maxDepth(Assets.depths)
    Camera.init(md)
    FishManager.init()
    ParticleManager.init()
end

-- ─────────────────────────────────────────────────────────────
--  love.update
-- ─────────────────────────────────────────────────────────────

function love.update(dt)
    timer = timer + dt
    ox, oy = distFromCenter(player.x, player.y)

    -- buoy bob
    local amplitude   = (Camera.offsetY < -90) and 1 or 12
    player.y          = baseY + math.sin(timer * 3) * amplitude
    player.rotation   = math.sin(timer * 3) * 0.02

    Camera.update(dt)
    FishManager.update(dt, Assets.layers, Assets.depths, mH, mW)
    ParticleManager.update(dt)

    -- catch feedback countdown
    if catchFeedback then
        catchFeedback.timer = catchFeedback.timer - dt
        if catchFeedback.timer <= 0 then catchFeedback = nil end
    end
end

-- ─────────────────────────────────────────────────────────────
--  love.draw
-- ─────────────────────────────────────────────────────────────

function love.draw()
    love.graphics.push()
    love.graphics.scale(scale, scale)

        -- world rotation (buoy bob)
        love.graphics.push()
        love.graphics.translate(mW / 2, mH / 2)
        love.graphics.rotate(player.rotation)
        love.graphics.scale(1.05, 1.05)
        love.graphics.translate(-mW / 2, -mH / 2)

            -- vertical scroll
            love.graphics.push()
            love.graphics.translate(0, Camera.offsetY)

                -- depth backgrounds
                local depthBgY = (mH - Assets.layers[#Assets.layers]:getHeight()) + 35
                love.graphics.draw(Assets.depths[5], 0, depthBgY +  Assets.depths[1]:getHeight() * 4 )
                love.graphics.draw(Assets.depths[4], 0, depthBgY +  Assets.depths[1]:getHeight() * 3 )
                love.graphics.draw(Assets.depths[3], 0, depthBgY +  Assets.depths[1]:getHeight() * 2 )
                love.graphics.draw(Assets.depths[2], 0, depthBgY + Assets.depths[1]:getHeight())
                love.graphics.draw(Assets.depths[1], 0, depthBgY)

                -- sky
                love.graphics.draw(Assets.stableSky, 0, -44 + oy / 10)

                -- water layers
                for i = 1, #Assets.layers do
                    love.graphics.draw(Assets.layers[i], 0,
                        (mH - Assets.layers[i]:getHeight()) + oy / 10 * i)
                end

                -- buoy
                love.graphics.draw(Assets.buoy, 0,
                    (mH - Assets.layers[#Assets.layers]:getHeight()) +
                    oy / 10 * #Assets.layers - Assets.buoy:getHeight())

                -- depth zone dark overlay
                if Camera.isInDepthZone() then
                    local df = Camera.depthFraction()
                    love.graphics.setColor(0, 0.05, 0.2, df * 0.45)
                    love.graphics.rectangle("fill", 0, 0, mW, mH * 4)
                    love.graphics.setColor(1, 1, 1, 1)
                end

                -- fish
                FishManager.draw(timer)

            love.graphics.pop()  -- scroll

        love.graphics.pop()  -- rotation

        -- ruler & pointer (fixed screen space, inside scale)
        HUD.drawRuler(
            Assets.ruler, Assets.pointer, Assets.depths,
            mW, mH, Camera.offsetY, Settings.DEPTH_ZONE_THRESHOLD)

    love.graphics.pop()  -- scale

    -- ── HUD (true screen-space pixels) ───────────────────────
    HUD.drawSurfaceButton(Assets.font, Camera.isInDepthZone())
    HUD.drawScore(Assets.font, score, wW)

    if not Camera.isInDepthZone() then
        HUD.drawDragHint(Assets.font, timer, wW, wH)
    end

    if Camera.isInDepthZone() and Camera.depthFraction() < 0.05 then
        HUD.drawDepthZoneBanner(Assets.font, wW, wH)
    end

    HUD.drawCatchFeedback(Assets.font, catchFeedback, wW, wH)
    ParticleManager.draw()
end

-- ─────────────────────────────────────────────────────────────
--  Input
-- ─────────────────────────────────────────────────────────────

function love.mousepressed(x, y, button)
    if button ~= 1 then return end

    -- surface button
    if HUD.hitsSurfaceBtn(x, y) then
        Camera.returnToSurface()
        FishManager.clear()
        return
    end

    -- fish click
    local idx = FishManager.hitTest(x, y)
    if idx then
        catchFish(idx)
        return
    end

    Camera.startDrag(y)
end

function love.mousereleased(x, y, button)
    if button == 1 then Camera.endDrag() end
end

function love.mousemoved(x, y, dx, dy)
    Camera.onDrag(y)
end