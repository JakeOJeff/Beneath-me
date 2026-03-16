

Settings        = require("src.conf.settings")
Assets          = require("src.systems.assets")
Camera          = require("src.systems.camera")
FishManager     = require("src.systems.fish_manager")
Particle        = require("src.classes.particle")
ParticleManager = require("src.systems.particle_manager")
HUD             = require("src.ui.hud")
MainMenu        = require("src.ui.mainmenu")
Market          = require("src.ui.market")
fishDefs        = require("src.conf.fish_defs")
Fish            = require("src.classes.fish")







local gameState = "menu"


local mW, mH, wW, wH, scale


local timer         = 0
local score         = 0
local catchFeedback = nil
local player        = { x = 0, y = 0, rotation = 0 }
local baseY         = 0
local ox, oy        = 0, 0





local function distFromCenter(x, y)
    return (mW / 2) - x, (mH / 2) - y
end

local function maxDepth(depths)
    return -(depths[1]:getHeight() * #depths - mH + 10)
end





local function catchFish(idx)
    local f   = FishManager.fish[idx]
    local def = f.def
    score = score + def.points

    local img = def.img
    ParticleManager.burst(
        (f.x + img:getWidth()  / 2) * scale,
        (f.y + Camera.offsetY  + img:getHeight() / 2) * scale,
        def.color[1], def.color[2], def.color[3])

    catchFeedback = {
        text  = "You have caught a " .. def.name
                .. " [" .. def.rarity .. "] worth " .. def.points .. " points!",
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
    scale  = Settings.SCALE
    wW, wH = mW * scale, mH * scale
    love.window.setMode(wW, wH)

    Assets.load()

    local md = maxDepth(Assets.depths)
    Camera.init(md)
    FishManager.init()
    ParticleManager.init()


    MainMenu.init(wW, wH)
end





function love.update(dt)
    if gameState == "menu" then
        MainMenu.update(dt)
        return
    end
    HUD.update(dt)

    if score > 30 then
        HUD.showTips(false)

    end


    timer = timer + dt
    ox, oy = distFromCenter(player.x, player.y)

    local amplitude = (Camera.offsetY < -90) and 1 or 12
    player.y        = baseY + math.sin(timer * 3) * amplitude
    player.rotation = math.sin(timer * 3) * 0.02

    Camera.update(dt)
    FishManager.update(dt, Assets.layers, Assets.depths, mH, mW)
    ParticleManager.update(dt)

    HUD.update(dt)
    Market.update(dt)

    if catchFeedback then
        catchFeedback.timer = catchFeedback.timer - dt
        if catchFeedback.timer <= 0 then catchFeedback = nil end
    end
end





function love.draw()

    if gameState == "menu" then
        MainMenu.draw(Assets.font)
        return
    end


    love.graphics.push()
    love.graphics.scale(scale, scale)

        love.graphics.push()
        love.graphics.translate(mW / 2, mH / 2)
        love.graphics.rotate(player.rotation)
        love.graphics.scale(1.05, 1.05)
        love.graphics.translate(-mW / 2, -mH / 2)

            love.graphics.push()
            love.graphics.translate(0, Camera.offsetY)

                local depthBgY = (mH - Assets.layers[#Assets.layers]:getHeight()) + 35
                love.graphics.draw(Assets.depths[5], 0, depthBgY + Assets.depths[1]:getHeight() * 4)
                love.graphics.draw(Assets.depths[4], 0, depthBgY + Assets.depths[1]:getHeight() * 3)
                love.graphics.draw(Assets.depths[3], 0, depthBgY + Assets.depths[1]:getHeight() * 2)
                love.graphics.draw(Assets.depths[2], 0, depthBgY + Assets.depths[1]:getHeight())
                love.graphics.draw(Assets.depths[1], 0, depthBgY)

                love.graphics.draw(Assets.stableSky, 0, -44 + oy / 10)

                for i = 1, #Assets.layers do
                    love.graphics.draw(Assets.layers[i], 0,
                        (mH - Assets.layers[i]:getHeight()) + oy / 10 * i)
                end

                love.graphics.draw(Assets.buoy, 0,
                    (mH - Assets.layers[#Assets.layers]:getHeight()) +
                    oy / 10 * #Assets.layers - Assets.buoy:getHeight())

                if Camera.isInDepthZone() then
                    local df = Camera.depthFraction()
                    love.graphics.setColor(0, 0.05, 0.2, df * 0.45)
                    love.graphics.rectangle("fill", 0, 0, mW, mH * 4)
                    love.graphics.setColor(1, 1, 1, 1)
                end

                FishManager.draw(timer)

            love.graphics.pop()
        love.graphics.pop()

        HUD.drawRuler(
            Assets.ruler, Assets.pointer, Assets.depths,
            mW, mH, Camera.offsetY, Settings.DEPTH_ZONE_THRESHOLD)

    love.graphics.pop()


    HUD.drawButton(Assets.font, Camera.isInDepthZone(), HUD.surfaceBtn)
    HUD.drawButton(Assets.font, true, HUD.inventoryBtn)
    HUD.drawButton(Assets.font, true, HUD.marketBtn)
    HUD.drawScore(Assets.font, score, wW)
    HUD.drawTip(Assets.font, wW)

    if not Camera.isInDepthZone() then
        HUD.drawDragHint(Assets.font, timer, wW, wH)
    end

    if Camera.isInDepthZone() and Camera.depthFraction() < 0.05 then
        HUD.drawDepthZoneBanner(Assets.font, wW, wH)
    end

    HUD.drawCatchFeedback(Assets.font, catchFeedback, wW, wH)
    ParticleManager.draw()


    HUD.drawInventory(Assets.font, FishManager.inventory, wW, wH)
    Market.draw(Assets.font, FishManager.inventory, score, wW, wH)
end





function love.mousepressed(x, y, button)
    if button ~= 1 then return end


    if gameState == "menu" then
        MainMenu.mousepressed(x, y, button, function()
            gameState = "playing"
        end)
        return
    end




    if Market.open then
        if Market.handleClick(x, y, wW, wH, FishManager.inventory,
            function(delta)
                score = math.max(0, score + delta)
            end) then
            return
        end
    end


    if HUD.handleInventoryClick(x, y, wW, wH) then return end


    if HUD.hitBtn(HUD.surfaceBtn, x, y) then
        Camera.returnToSurface()
        FishManager.clear()
        return
    end


    if HUD.hitBtn(HUD.inventoryBtn, x, y) then
        HUD.toggleInventory()

        if HUD.inventoryOpen then Market.open = false end
        return
    end


    if HUD.hitBtn(HUD.marketBtn, x, y) then
        Market.toggle(score)

        if Market.open then HUD.inventoryOpen = false end
        return
    end


    if not HUD.inventoryOpen and not Market.open then
        local idx = FishManager.hitTest(x, y)
        if idx then
            catchFish(idx)
            return
        end
        Camera.startDrag(y)
    end
end

function love.mousereleased(x, y, button)
    if gameState ~= "playing" then return end
    if button == 1 then Camera.endDrag() end
end

function love.mousemoved(x, y, dx, dy)
    if gameState ~= "playing" then return end
    if not HUD.inventoryOpen and not Market.open then
        Camera.onDrag(y)
    end
end

function love.wheelmoved(x, y)
    if gameState ~= "playing" then return end
    local mx, my = love.mouse.getPosition()

    if Market.open then
        Market.onWheel(mx, my, y, wW, wH)
    else
        HUD.onWheel(mx, my, x, y, wW, wH)
    end
end
